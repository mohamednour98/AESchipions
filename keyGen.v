module keyGen(
   input wire            clk,
   input wire            reset,
   input wire [127 : 0]  key,
   input wire            init,
   input wire    [3 : 0] round,
   output wire [127 : 0] roundKey,
   output wire           ready,
   output wire [31 : 0]  beforeSub,
   input wire  [31 : 0]  afterSub
  );


  localparam CtrlIdle     = 3'h0;
  localparam CtrlInit     = 3'h1;
  localparam CtrlGen = 3'h2;
  localparam CtrlDone     = 3'h3;


  reg [127 : 0] keyMem [0 : 9];
  reg [127 : 0] keyMemNew;
  reg           keyMemWE;

  reg [127 : 0] prevKeyReg;
  reg [127 : 0] prevKeyNew;
  reg           prevKey;

  reg [3 : 0] roundCtrReg;
  reg [3 : 0] roundCtrNew;
  reg         roundCtrReset;
  reg         roundCtrIncrement;
  reg         roundCtrWE;

  reg [2 : 0] CtrlReg;
  reg [2 : 0] CtrlNew;
  reg         CtrlWE;

  reg         readyReg;
  reg         readyNew;
  reg         readyWE;

  reg [7 : 0] rConReg;
  reg [7 : 0] rConNew;
  reg         rConWE;
  reg         rConSet;
  reg         rConNext;


  reg [31 : 0]  tempBeforeSub;
  reg           roundKeyUpdate;
  reg [127 : 0] tempRoundKey;

  assign roundKey = tempRoundKey;
  assign ready     = readyReg;
  assign beforeSub     = tempBeforeSub;


  always @ (posedge clk or negedge reset)
    begin: regUpdate
      integer i;

      if (!reset)
        begin
          for (i = 0 ; i <= 10 ; i = i + 1)
            keyMem [i] <= 128'h0;

          rConReg         <= 8'h0;
          readyReg        <= 1'b0;
          roundCtrReg    <= 4'h0;
          CtrlReg <= CtrlIdle;
        end
      else
        begin
          if (roundCtrWE)
            roundCtrReg <= roundCtrNew;

          if (readyWE)
            readyReg <= readyNew;

          if (rConWE)
            rConReg <= rConNew;

          if (keyMemWE)
            keyMem[roundCtrReg] <= keyMemNew;

          if (prevKey)
            prevKeyReg <= prevKeyNew;

          if (CtrlWE)
            CtrlReg <= CtrlNew;
        end
    end 


  always @* begin : key_mem_read
    tempRoundKey = keyMem[round];
  end 

  always @* begin: round_key_gen
    reg [31 : 0] w0, w1, w2, w3, w4, w5, w6, w7;
    reg [31 : 0] k0, k1, k2, k3;
    reg [31 : 0] rconw, rotstw, tw, trw;

    // Default assignments.
    keyMemNew   = 128'h0;
    keyMemWE    = 1'b0;
    prevKeyNew = 128'h0;
    prevKey  = 1'b0;

    k0 = 32'h0;
    k1 = 32'h0;
    k2 = 32'h0;
    k3 = 32'h0;

    rConSet   = 1'b1;
    rConNext  = 1'b0;

    // Extract words and calculate intermediate values.
    // Perform rotation of sbox word etc.
    w4 = prevKeyReg[127 : 096];
    w5 = prevKeyReg[095 : 064];
    w6 = prevKeyReg[063 : 032];
    w7 = prevKeyReg[031 : 000];

    rconw = {rConReg, 24'h0};
    tempBeforeSub = w7;
    rotstw = {afterSub[23 : 00], afterSub[31 : 24]};
    trw = rotstw ^ rconw;
    tw = afterSub;

    // Generate the specific round keys.
    if (roundKeyUpdate)
      begin
        rConSet   = 1'b0;
        keyMemWE = 1'b1;

      if (roundCtrReg == 0)
        begin
          keyMemNew   = key[127 : 0];
          prevKeyNew = key[127 : 0];
          prevKey  = 1'b1;
          rConNext     = 1'b1;
        end
      else
        begin
          k0 = w4 ^ trw;
          k1 = w5 ^ w4 ^ trw;
          k2 = w6 ^ w5 ^ w4 ^ trw;
          k3 = w7 ^ w6 ^ w5 ^ w4 ^ trw;   
          keyMemNew   = {k0, k1, k2, k3};
          prevKeyNew = {k0, k1, k2, k3};
          prevKey  = 1'b1;
          rConNext     = 1'b1;
        end

      end
  end // round_key_gen



  always @*
    begin : rcon_logic
      reg [7 : 0] tempRCon;
      rConNew = 8'h00;
      rConWE  = 1'b0;

      tempRCon = {rConReg[6 : 0], 1'b0} ^ (8'h1b & {8{rConReg[7]}});

      if (rConSet)
        begin
          rConNew = 8'h8d;
          rConWE  = 1'b1;
        end

      if (rConNext)
        begin
          rConNew = tempRCon[7 : 0];
          rConWE  = 1'b1;
        end
    end


  always @*
    begin : roundCtr
      roundCtrNew = 4'h0;
      roundCtrWE  = 1'b0;

      if (roundCtrReset)
        begin
          roundCtrNew = 4'h0;
          roundCtrWE  = 1'b1;
        end

      else if (roundCtrIncrement)
        begin
          roundCtrNew = roundCtrReg + 1'b1;
          roundCtrWE  = 1'b1;
        end
    end


  always @*
    begin: key_mem_ctrl
      reg [3 : 0] numOfRounds = 10;

      // Default assignments.
      readyNew        = 1'b0;
      readyWE         = 1'b0;
      roundKeyUpdate = 1'b0;
      roundCtrReset    = 1'b0;
      roundCtrIncrement    = 1'b0;
      CtrlNew = CtrlIdle;
      CtrlWE  = 1'b0;

      case(CtrlReg)
        CtrlIdle:
          begin
            if (init)
              begin
                readyNew        = 1'b0;
                readyWE         = 1'b1;
                CtrlNew = CtrlInit;
                CtrlWE  = 1'b1;
              end
          end

        CtrlInit:
          begin
            roundCtrReset    = 1'b1;
            CtrlNew = CtrlGen;
            CtrlWE  = 1'b1;
          end

        CtrlGen:
          begin
            roundCtrIncrement    = 1'b1;
            roundKeyUpdate = 1'b1;
            if (roundCtrReg == numOfRounds)
              begin
                CtrlNew = CtrlDone;
                CtrlWE  = 1'b1;
              end
          end

        CtrlDone:
          begin
            readyNew        = 1'b1;
            readyWE         = 1'b1;
            CtrlNew = CtrlIdle;
            CtrlWE  = 1'b1;
          end

        default:
          begin
          end
      endcase // case (CtrlReg)

    end // key_mem_ctrl
endmodule // aes_key_mem
