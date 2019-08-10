module EncryptionBlock(
    input wire            clk,
    input wire            reset,
    input wire            next,

    output wire [3 : 0]   round,
    input wire [127 : 0]  roundKey,
    output wire [31 : 0]  sBoxRequest,
    input wire  [31 : 0]  sBoxResponse,
    input wire [127 : 0]  block,
    output wire [127 : 0] newBlock,
    output wire           ready
  );

  localparam noUpdate    = 3'h0;
  localparam initUpdate  = 3'h1;
  localparam sBoxUpdate  = 3'h2;
  localparam mainUpdate  = 3'h3;
  localparam finalUpdate = 3'h4;

  localparam ctrlIdle  = 3'h0;
  localparam ctrlInit  = 3'h1;
  localparam ctrlSBox  = 3'h2;
  localparam ctrlMain  = 3'h3;
  localparam ctrlFinal = 3'h4;


  function [7 : 0] mult2(input [7 : 0] op);
    begin
      mult2 = {op[6 : 0], 1'b0} ^ (8'h1b & {8{op[7]}});
    end
  endfunction

  function [7 : 0] mult3(input [7 : 0] op);
    begin
      mult3 = mult2(op) ^ op;
    end
  endfunction

  function [31 : 0] mixWord(input [31 : 0] word);
    reg [7 : 0] b0, b1, b2, b3;
    reg [7 : 0] mb0, mb1, mb2, mb3;
    begin
      b0 = word[31 : 24];
      b1 = word[23 : 16];
      b2 = word[15 : 08];
      b3 = word[07 : 00];

      mb0 = mult2(b0) ^ mult3(b1) ^ b2      ^ b3;
      mb1 = b0      ^ mult2(b1) ^ mult3(b2) ^ b3;
      mb2 = b0      ^ b1      ^ mult2(b2) ^ mult3(b3);
      mb3 = mult3(b0) ^ b1      ^ b2      ^ mult2(b3);

      mixWord = {mb0, mb1, mb2, mb3};
    end
  endfunction

  function [127 : 0] mixColumns(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = mixWord(w0);
      ws1 = mixWord(w1);
      ws2 = mixWord(w2);
      ws3 = mixWord(w3);

      mixColumns = {ws0, ws1, ws2, ws3};
    end
  endfunction

  function [127 : 0] shiftRows(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = {w0[31 : 24], w1[23 : 16], w2[15 : 08], w3[07 : 00]};
      ws1 = {w1[31 : 24], w2[23 : 16], w3[15 : 08], w0[07 : 00]};
      ws2 = {w2[31 : 24], w3[23 : 16], w0[15 : 08], w1[07 : 00]};
      ws3 = {w3[31 : 24], w0[23 : 16], w1[15 : 08], w2[07 : 00]};

      shiftRows = {ws0, ws1, ws2, ws3};
    end
  endfunction

  function [127 : 0] addRoundKey(input [127 : 0] data, input [127 : 0] rKey);
    begin
      addRoundKey = data ^ rKey;
    end
  endfunction

  reg [1 : 0]   sWordCTRReg;
  reg [1 : 0]   sWordCTRNew;
  reg           sWordCTRWE;
  reg           sWordCTRInc;
  reg           sWordCTRReset;

  reg [3 : 0]   roundCTRReg;
  reg [3 : 0]   roundCTRNew;
  reg           roundCTRWE;
  reg           roundCTRReset;
  reg           roundCTRInc;

  reg [127 : 0] blockNew;
  reg [31 : 0]  w0Reg;
  reg [31 : 0]  w1Reg;
  reg [31 : 0]  w2Reg;
  reg [31 : 0]  w3Reg;
  reg           w0WE;
  reg           w1WE;
  reg           w2WE;
  reg           w3WE;

  reg           readyReg;
  reg           readyNew;
  reg           readyWE;

  reg [2 : 0]   ctrlReg;
  reg [2 : 0]   ctrlNew;
  reg           ctrlWE;

  reg [2 : 0]  updateType;
  reg [31 : 0] selSBoxRequest;

  assign round     = roundCTRReg;
  assign sBoxRequest     = selSBoxRequest;
  assign newBlock = {w0Reg, w1Reg, w2Reg, w3Reg};
  assign ready     = readyReg;

  always @ (posedge clk or negedge reset)
    begin: regUpdate
      if (!reset)
        begin
          w0Reg  <= 32'h0;
          w1Reg  <= 32'h0;
          w2Reg  <= 32'h0;
          w3Reg  <= 32'h0;
          sWordCTRReg <= 2'h0;
          roundCTRReg <= 4'h0;
          readyReg     <= 1'b1;
          ctrlReg  <= ctrlIdle;
        end
      else
        begin
          if (w0WE)
            w0Reg <= blockNew[127 : 096];

          if (w1WE)
            w1Reg <= blockNew[095 : 064];

          if (w2WE)
            w2Reg <= blockNew[063 : 032];

          if (w3WE)
            w3Reg <= blockNew[031 : 000];

          if (sWordCTRWE)
            sWordCTRReg <= sWordCTRNew;

          if (roundCTRWE)
            roundCTRReg <= roundCTRNew;

          if (readyWE)
            readyReg <= readyNew;

          if (ctrlWE)
            ctrlReg <= ctrlNew;
        end
    end

  always @*
    begin : roundLogic
      reg [127 : 0] oldBlock, shiftRowsBlock, mixColumnsBlock;
      reg [127 : 0] initBlock, mainBlock, finalBlock;

      blockNew   = 128'h0;
      selSBoxRequest = 32'h0;
      w0WE = 1'b0;
      w1WE = 1'b0;
      w2WE = 1'b0;
      w3WE = 1'b0;

      oldBlock          = {w0Reg, w1Reg, w2Reg, w3Reg};
      shiftRowsBlock    = shiftRows(oldBlock);
      mixColumnsBlock   = mixColumns(shiftRowsBlock);
      initBlock  = addRoundKey(block, roundKey);
      mainBlock  = addRoundKey(mixColumnsBlock, roundKey);
      finalBlock = addRoundKey(shiftRowsBlock, roundKey);

      case (updateType)
        initUpdate:
          begin
            blockNew    = initBlock;
            w0WE  = 1'b1;
            w1WE  = 1'b1;
            w2WE  = 1'b1;
            w3WE  = 1'b1;
          end

        sBoxUpdate:
          begin
            blockNew = {sBoxResponse, sBoxResponse, sBoxResponse, sBoxResponse};

            case (sWordCTRReg)
              2'h0:
                begin
                  selSBoxRequest = w0Reg;
                  w0WE = 1'b1;
                end

              2'h1:
                begin
                  selSBoxRequest = w1Reg;
                  w1WE = 1'b1;
                end

              2'h2:
                begin
                  selSBoxRequest = w2Reg;
                  w2WE = 1'b1;
                end

              2'h3:
                begin
                  selSBoxRequest = w3Reg;
                  w3WE = 1'b1;
                end
            endcase
          end

        mainUpdate:
          begin
            blockNew    = mainBlock;
            w0WE  = 1'b1;
            w1WE  = 1'b1;
            w2WE  = 1'b1;
            w3WE  = 1'b1;
          end

        finalUpdate:
          begin
            blockNew    = finalBlock;
            w0WE  = 1'b1;
            w1WE  = 1'b1;
            w2WE  = 1'b1;
            w3WE  = 1'b1;
          end

        default:
          begin
          end
      endcase
    end

  always @*
    begin : sWordCTR
      sWordCTRNew = 2'h0;
      sWordCTRWE  = 1'b0;

      if (sWordCTRReset)
        begin
          sWordCTRNew = 2'h0;
          sWordCTRWE  = 1'b1;
        end
      else if (sWordCTRInc)
        begin
          sWordCTRNew = sWordCTRReg + 1'b1;
          sWordCTRWE  = 1'b1;
        end
    end

  always @*
    begin : roundCTR
      roundCTRNew = 4'h0;
      roundCTRWE  = 1'b0;

      if (roundCTRReset)
        begin
          roundCTRNew = 4'h0;
          roundCTRWE  = 1'b1;
        end
      else if (roundCTRInc)
        begin
          roundCTRNew = roundCTRReg + 1'b1;
          roundCTRWE  = 1'b1;
        end
    end

  always @*
    begin: ctrl
      reg [3 : 0] numOfRounds;

      sWordCTRInc = 1'b0;
      sWordCTRReset = 1'b0;
      roundCTRInc = 1'b0;
      roundCTRReset = 1'b0;
      readyNew     = 1'b0;
      readyWE      = 1'b0;
      updateType   = noUpdate;
      ctrlNew  = ctrlIdle;
      ctrlWE   = 1'b0;
      numOfRounds = 4'ha;

      case(ctrlReg)
        ctrlIdle:
          begin
            if (next)
              begin
                roundCTRReset = 1'b1;
                readyNew     = 1'b0;
                readyWE      = 1'b1;
                ctrlNew  = ctrlInit;
                ctrlWE   = 1'b1;
              end
          end

        ctrlInit:
          begin
            roundCTRInc = 1'b1;
            sWordCTRReset = 1'b1;
            updateType   = initUpdate;
            ctrlNew  = ctrlSBox;
            ctrlWE   = 1'b1;
          end

        ctrlSBox:
          begin
            sWordCTRInc = 1'b1;
            updateType   = sBoxUpdate;
            if (sWordCTRReg == 2'h3)
              begin
                ctrlNew  = ctrlMain;
                ctrlWE   = 1'b1;
              end
          end

        ctrlMain:
          begin
            sWordCTRReset = 1'b1;
            roundCTRInc = 1'b1;
            if (roundCTRReg < numOfRounds)
              begin
                updateType   = mainUpdate;
                ctrlNew  = ctrlSBox;
                ctrlWE   = 1'b1;
              end
            else
              begin
                updateType  = finalUpdate;
                readyNew    = 1'b1;
                readyWE     = 1'b1;
                ctrlNew = ctrlIdle;
                ctrlWE  = 1'b1;
              end
          end

        default: begin end
      endcase 
    end

endmodule