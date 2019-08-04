module EncryptionBlock(
  input wire clk,
  input wire reset,
  input wire next,
  output wire[3:0] round,
  input wire[127:0] roundKey,
  output wire[31:0] beforeSub,
  input wire[31:0] afterSub,
  input wire[127:0] block,
  output wire[127:0] newBlock,
  output wire ready
);

  localparam rounds = 4'ha;

  //updateType State

  localparam noUpdate = 3'h0;
  localparam initUpdate = 3'h1;
  localparam sBoxUpdate = 3'h2;
  localparam mainUpdate = 3'h3;
  localparam finalUpdate = 3'h4;

  //ctrl state

  localparam ctrlIdle = 2'h0;
  localparam ctrlInit = 2'h1;
  localparam ctrlSBox = 2'h2;
  localparam ctrlMain = 2'3;

  //functions for mixing columns and shifting rows

  function [7:0] multiply02(input[7:0] op);
    begin
      //Mix columns multiply by 02
      multiply02 = {op[6:0], 1'b0} ^ (8'h1b & {8{op[7]}});
    end
  endfunction

  function [7:0] multiply03(input[7:0] op);
    begin
      //mix columns multiply by 03
      multiply03 = multiply02(op) ^ op;
    end
  endfunction

  function [31:0] mixWord(input[31:0] word);
    
    reg[7:0] block0, block1, block2, block3;
    reg[7:0] mBlock0, mBlock1, mBlock2, mBlock3;

    begin
      block0 = word[31:24];
      block1 = word[23:16];
      block2 = word[15:08];
      block3 = word[07:00];

      mBlock0 = multiply02(block0) ^ multiply03(block1) ^ block2 ^ block3;
      mBlock1 = block0 ^ multiply02(block1) ^ multiply03(block2) ^ block3;
      mBlock2 = block0 ^ block1 ^ multiply02(block2) ^ multiply03(block3);
      mBlock3 = multiply03(block0) ^ block1 ^ block2 ^ multiply02(block3);
      
      mixWord = {mBlock0, mBlock1, mBlock2, mBlock3};
    end
  endfunction

  function [127:0] mixColumns(input [127:0] data);

    reg[31:0] word0, word1, word2, word3;
    reg[31:0] mWord0, mWord1, mWord2, mWord3;
    
    begin
      word0 = data[127:096];
      word1 = data[095:064];
      word2 = data[063:032];
      word3 = data[031:000];

      mWord0 = mixWord(word0);
      mWord1 = mixWord(word1);
      mWord2 = mixWord(word2);
      mWord3 = mixWord(word3);

      mixColumns = {mWord0, mWord1, mWord2, mWord3};
    end

  endfunction

  function [127:0] shiftRows(input[127:0] data);

    reg[31:0] word0, word1, word2, word3;
    reg[31:0] mWord0, mWord1, mWord2, mWord3;

    begin
      word0 = data[127:096];
      word1 = data[095:064];
      word2 = data[063:032];
      word3 = data[031:000];

      mWord0 = {word0[31:24], word1[23:16], word2[15:08], word3[07:00]};
      mWord1 = {word1[31:24], word2[23:16], word3[15:08], word0[07:00]};
      mWord2 = {word2[31:24], word3[23:16], word0[15:08], word1[07:00]};
      mWord3 = {word3[31:24], word0[23:16], word1[15:08], word2[07:00]};

      shiftRows = {mWord0, mWord1, mWord2, mWord3};

    end

  endfunction

  function [127:0] addRoundKey(input[127:0] data, input[127:0] roundKey);
    begin
      addRoundKey = data ^ roundKey;
    end
  endfunction

  reg[1:0] sWordCtrReg;
  reg[1:0] sWordCtrNew;
  reg sWordCtrWE;
  reg sWordCtrInc;
  reg sWordCtrReset;

  reg[3:0] roundCtrReg;
  reg[3:0] roundCtrNew;
  reg roundCtrInc;
  reg roundCtrWE;
  reg roundCtrReset;

  reg[127:0] blockNew;
  reg[31:0] block0Reg;
  reg[31:0] block1Reg;
  reg[31:0] block2Reg;
  reg[31:0] block3Reg;
  reg block0WE;
  reg block1WE;
  reg block2WE;
  reg block3WE;

  reg readyReg;
  reg readyNew;
  reg readyWE;

  reg[2:0] ctrlReg;
  reg[2:0] ctrlNew;
  reg ctrlWE;

  reg[2:0] updateType;
  reg[31:0] selSBox;

  assign round = roundCtrReg;
  assign beforeSub = selSBox;
  assign newBlock = {block0Reg, block1Reg, block2Reg, block3Reg};
  assign ready = readyReg;

  //main sequencial block

  always@(posedge clk or negedge reset) begin

    if(!reset) begin
      block0Reg <= 32'h0;
      block1Reg <= 32'h0;
      block2Reg <= 32'h0;
      block3Reg <= 32'h0;
      sWordCtrReg <= 2'h0;
      roundCtrReg <= 4'h0;
      readyReg <= 1'b1;
      ctrlReg <= ctrlIdle;
    end
    else begin

      if(block0WE)
        block0Reg <= blockNew[127:096];
      if(block1WE)
        block0Reg <= blockNew[095:064];
      if(block2WE)
        block0Reg <= blockNew[063:032];
      if(block3WE)
        block0Reg <= blockNew[031:000];
      
      if(sWordCtrWE)
        sWordCtrReg <= sWordCtrNew;
      if(roundCtrWE)
        roundCtrReg <= roundCtrNew;
      if(readyWE)
        readyReg <= readyNew;
      if(ctrlWE)
        ctrlReg <= ctrlNew;        
    end
  end

  //updateType FSM

  always@(*) begin

    reg[127:0] oldBlock, shiftRowsBlock, mixColumnsBlock;
    reg[127:0] addKeyInitBlock, addKeyMainBlock, addKeyFinalBlock;

    blockNew = 128'h0;
    selSBox = 32'h0;
    block0WE = 1'b0;
    block1WE = 1'b0;
    block2WE = 1'b0;
    block3WE = 1'b0;

    oldBlock = {block0Reg, block1Reg, block2Reg, block3Reg};
    shiftRowsBlock = shiftRows(oldBlock);
    mixColumnsBlock = mixColumns(shiftRowsBlock);
    addKeyInitBlock = addRoundKey(block, roundKey);
    addKeyMainBlock = addRoundKey(mixColumnsBlock, roundKey);
    addKeyMainBlock = addRoundKey(shiftRowsBlock, roundKey);

    case(updateType)
      initUpdate: begin
        blockNew = addKeyInitBlock;
        block0WE = 1'b1;
        block1WE = 1'b1;
        block2WE = 1'b1;
        block3WE = 1'b1;
      end

      sBoxUpdate: begin
        blockNew = {afterSub, afterSub, afterSub, afterSub};

        case(sWordCtrReg)
          2'h0: begin
            selSBox = block0Reg;
            block0WE = 1'b1;
          end
          2'h1: begin
            selSBox = block1Reg;
            block1WE = 1'b1;
          end
          2'h2: begin
            selSBox = block2Reg;
            block2WE = 1'b1;
          end
          2'h3: begin
            selSBox = block3Reg;
            block3WE = 1'b1;
          end
        endcase
      end

      mainUpdate: begin
        blockNew = addKeyMainBlock;
        block0WE = 1'b1;
        block1WE = 1'b1;
        block2WE = 1'b1;
        block3WE = 1'b1;
      end

      finalUpdate: begin
        blockNew = addKeyFinalBlock;
        block0WE = 1'b1;
        block1WE = 1'b1;
        block2WE = 1'b1;
        block3WE = 1'b1;
      end
      default: begin end
    endcase
  end

  //round counter control

  always@(*) begin
    roundCtrNew = 4'h0;
    roundCtrWE = 1'b0;

    if(roundCtrReset) begin
      roundCtrNew = 4'h0;
      roundCtrWE = 1'b1;
    end

    else if(roundCtrInc) begin
      roundCtrNew = roundCtrReg + 1'b1;
      roundCtrWE = 1'b1;
    end
  end

  //ctrl FSM

  always@(*) begin

    sWordCtrInc = 1'b0;
    sWordCtrReset = 1'b0;
    roundCtrInc = 1'b0;
    roundCtrReset = 1'b0;
    readyNew = 1'b0;
    readyWE = 1'b0;
    updateType = noUpdate;
    ctrlNew = ctrlIdle;
    ctrlWE = 1'b0;

    case(ctrlReg)

      ctrlIdle: begin
        if(next) begin
          roundCtrReset = 1'b1;
          readyNew = 1'b0;
          readyWE = 1'b1;
          ctrlNew = ctrlInit;
          ctrlWE = 1'b1;
        end
      end

      ctrlInit: begin
        roundCtrInc = 1'b1;
        sWordCtrReset = 1'b1;
        updateType = initUpdate;
        ctrlNew = ctrlSBox;
        ctrlWE = 1'b1;
      end

      ctrlMain: begin
        sWordCtrReset = 1'b1;
        roundCtrInc = 1'b1;
        if(roundCtrReg < rounds) begin
          updateType = mainUpdate;
          ctrlNew = ctrlSBox;
          ctrlWE = 1'b1;
        end
        else begin
          updateType = finalUpdate;
          readyNew = 1'b1;
          readyWE = 1'b1;
          ctrlNew = ctrlIdle;
          ctrlWE = 1'b1;
        end
      end
      default: begin end
    endcase
  end

endmodule