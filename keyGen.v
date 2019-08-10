module KeyGen(
    input wire            clk,
    input wire            reset,
    input wire [127 : 0]  key,                    
    input wire            init,
    input wire    [3 : 0] round,
    output wire [127 : 0] roundKey,
    output wire           ready,  
    output wire [31 : 0]  sBoxRequest,
    input wire  [31 : 0]  sBoxResponse
  );

  localparam ctrlIdle = 3'h0;
  localparam ctrlInit = 3'h1;
  localparam ctrlGen = 3'h2;
  localparam ctrlDone = 3'h3;

  reg [127 : 0] keyMemory [0 : 14];
  reg [127 : 0] keyMemoryNew;
  reg           keyMemoryWE;

  reg [127 : 0] prevK1Reg;
  reg [127 : 0] prevK1New;
  reg           prevK1WE;

  reg [3 : 0] roundCTRReg;
  reg [3 : 0] roundCTRNew;
  reg         roundCTRReset;
  reg         roundCTRInc;
  reg         roundCTRWE;

  reg [2 : 0] ctrlReg;
  reg [2 : 0] ctrlNew;
  reg         ctrlWE;

  reg         readyReg;
  reg         readyNew;
  reg         readyWE;

  reg [7 : 0] rConReg;
  reg [7 : 0] rConNew;
  reg         rConWE;
  reg         rConSet;
  reg         rConNext;

  reg [31 : 0]  tempSBoxRequest;
  reg           roundKeyUpdate;
  reg [127 : 0] tempRoundKey;

  assign roundKey = tempRoundKey;
  assign ready     = readyReg;
  assign sBoxRequest     = tempSBoxRequest;

  always @ (posedge clk or negedge reset)
    begin: regUpdate
      integer i;

      if (!reset)
        begin
          for (i = 0 ; i <= 10 ; i = i + 1)
            keyMemory [i] <= 128'h0;

          rConReg         <= 8'h0;
          readyReg        <= 1'b0;
          roundCTRReg    <= 4'h0;
          ctrlReg <= ctrlIdle;
        end
      else
        begin
          if (roundCTRWE)
            roundCTRReg <= roundCTRNew;

          if (readyWE)
            readyReg <= readyNew;

          if (rConWE)
            rConReg <= rConNew;

          if (keyMemoryWE)
            keyMemory[roundCTRReg] <= keyMemoryNew;

          if (prevK1WE)
            prevK1Reg <= prevK1New;

          if (ctrlWE)
            ctrlReg <= ctrlNew;
        end
    end 

  always @*
    begin : memoryRead
      tempRoundKey = keyMemory[round];
    end 

  always @*
    begin: roundKeyGen
      reg [31 : 0] w0, w1, w2, w3;
      reg [31 : 0] k0, k1, k2, k3;
      reg [31 : 0] rconw, rotstw, tw, trw;

      keyMemoryNew   = 128'h0;
      keyMemoryWE    = 1'b0;
      prevK1New = 128'h0;
      prevK1WE  = 1'b0;

      k0 = 32'h0;
      k1 = 32'h0;
      k2 = 32'h0;
      k3 = 32'h0;

      rConSet   = 1'b1;
      rConNext  = 1'b0;

      w0 = prevK1Reg[127 : 096];
      w1 = prevK1Reg[095 : 064];
      w2 = prevK1Reg[063 : 032];
      w3 = prevK1Reg[031 : 000];

      rconw = {rConReg, 24'h0};
      tempSBoxRequest = w3;
      rotstw = {sBoxResponse[23 : 00], sBoxResponse[31 : 24]};
      trw = rotstw ^ rconw;
      tw = sBoxResponse;

      if (roundKeyUpdate)
        begin
          rConSet   = 1'b0;
          keyMemoryWE = 1'b1;
            
          if (roundCTRReg == 0)
            begin
              keyMemoryNew   = key[127 : 0];
              prevK1New = key[127 : 0];
              prevK1WE  = 1'b1;
              rConNext     = 1'b1;
          end
          else
            begin
              k0 = w0 ^ trw;
              k1 = w1 ^ w0 ^ trw;
              k2 = w2 ^ w1 ^ w0 ^ trw;
              k3 = w3 ^ w2 ^ w1 ^ w0 ^ trw;

              keyMemoryNew   = {k0, k1, k2, k3};
              prevK1New = {k0, k1, k2, k3};
              prevK1WE  = 1'b1;
              rConNext     = 1'b1;
            end
        end
    end

  always @*
    begin : rConLogic
      reg [7 : 0] tmp_rcon;
      rConNew = 8'h00;
      rConWE  = 1'b0;

      tmp_rcon = {rConReg[6 : 0], 1'b0} ^ (8'h1b & {8{rConReg[7]}});

      if (rConSet)
        begin
          rConNew = 8'h8d;
          rConWE  = 1'b1;
        end

      if (rConNext)
        begin
          rConNew = tmp_rcon[7 : 0];
          rConWE  = 1'b1;
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
    begin: memoryCtrl
      reg [3 : 0] numOfRounds;

      readyNew        = 1'b0;
      readyWE         = 1'b0;
      roundKeyUpdate = 1'b0;
      roundCTRReset    = 1'b0;
      roundCTRInc    = 1'b0;
      ctrlNew = ctrlIdle;
      ctrlWE  = 1'b0;
      numOfRounds = 10;
   
      case(ctrlReg)
        ctrlIdle:
          begin
            if (init)
              begin
                readyNew        = 1'b0;
                readyWE         = 1'b1;
                ctrlNew = ctrlInit;
                ctrlWE  = 1'b1;
              end
          end

        ctrlInit:
          begin
            roundCTRReset    = 1'b1;
            ctrlNew = ctrlGen;
            ctrlWE  = 1'b1;
          end

        ctrlGen:
          begin
            roundCTRInc    = 1'b1;
            roundKeyUpdate = 1'b1;
            if (roundCTRReg == numOfRounds)
              begin
                ctrlNew = ctrlDone;
                ctrlWE  = 1'b1;
              end
          end

        ctrlDone:
          begin
            readyNew        = 1'b1;
            readyWE         = 1'b1;
            ctrlNew = ctrlIdle;
            ctrlWE  = 1'b1;
          end

        default: begin end
      endcase 
    end
endmodule