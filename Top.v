module Top(
  input wire next,
  input wire clk,
  input wire init,
  input wire reset,
  input wire[127:0] data,
  input wire[127:0] key,
  output wire[127:0] outData,
  output wire ready
);

  localparam ctrlIdle  = 2'h0;
  localparam ctrlInit  = 2'h1;
  localparam ctrlNext  = 2'h2;


  wire[63:0] count;
  wire[63:0] nonce;

  wire[127 : 0] roundKey;
  wire          keyReady;


  wire[3 : 0]   encRoundNum;
  wire[127 : 0] encNewBlock;
  wire          encReady;
  wire[31 : 0]  encSBoxRequest;

 
  wire[127 : 0] nonceIv;
  wire[31 : 0]  keySBoxRequest;
  wire[31 : 0]  sBoxResponse;

  reg           encNext;
  reg[31 : 0]   selSBoxRequest;	
  reg           initState;
  reg[127 : 0]  selNewBlock;
  reg[3 : 0]    selRoundNum;
  reg           selReady;
  reg[1 : 0] ctrlReg;
  reg[1 : 0] ctrlNew;
  reg        ctrlWE;

  reg        readyReg;
  reg        readyNew;
  reg        readyWE;
  reg [127:0]resultOut;
  assign ready        = readyReg;
  assign result       = selNewBlock;
  assign outData      = resultOut;
  assign nonceIv={nonce[63:0], count[63:0]};

  KeyGen keyGenInst(
    .clk(clk),
    .reset(reset),
    .key(key),
    .init(init),
    .round(selRoundNum),
    .roundKey(roundKey),
    .ready(keyReady),
    .sBoxRequest(keySBoxRequest),
    .sBoxResponse(sBoxResponse)
  );

  EncryptionBlock encryptor(
    .clk(clk),
    .reset(reset),
    .next(encNext),
    .round(encRoundNum),
    .roundKey(roundKey),
    .sBoxRequest(encSBoxRequest),
    .sBoxResponse(sBoxResponse),
    .block(nonceIv),
    .newBlock(encNewBlock),
    .ready(encReady)
  );

  SubBox subBoxInst(
	  .sBoxRequest(selSBoxRequest), 
	  .sBoxResponse(sBoxResponse)
  );

  Counter counting(
    .clk(next),
    .reset(reset),
    .count(count)
  );
  random fornonce(
    .reset(reset),
    .outData(nonce)
  );

  always @*
    begin : sBoxSel
      if (initState)
        begin
          selSBoxRequest = keySBoxRequest;
        end
      else
        begin
          selSBoxRequest = encSBoxRequest;
        end
    end

  always @*
    begin : resultXOR
      if (encReady)
        begin
          resultOut = encNewBlock ^ data;
        end
      else
        begin
           resultOut = 128'h0;
        end
    end 

  always @ (posedge clk or negedge reset)
    begin: regUpdate
      if (!reset)
        begin
          readyReg         <= 1'b1;
          ctrlReg <= ctrlIdle;
        end
      else
        begin
          if (readyWE)
            readyReg <= readyNew;
          if (ctrlWE)
            ctrlReg <= ctrlNew;
        end
    end 
  always @*
    begin 
      encNext = 1'b0;
      encNext        = next;
      selRoundNum  = encRoundNum;
      selNewBlock = encNewBlock;
      selReady     = encReady;  
    end 

    always @*
    begin : ctrl
      initState        = 1'b0;
      readyNew         = 1'b0;
      readyWE          = 1'b0;

      ctrlNew = ctrlIdle;
      ctrlWE  = 1'b0;

      case (ctrlReg)
        ctrlIdle:
          begin
            if (init)
              begin
                initState        = 1'b1;
                readyNew         = 1'b0;
                readyWE          = 1'b1;

                ctrlNew = ctrlInit;
                ctrlWE  = 1'b1;
              end
            else if (next)
              begin
                initState        = 1'b0;
                readyNew         = 1'b0;
                readyWE          = 1'b1;
               
                ctrlNew = ctrlNext;
                ctrlWE  = 1'b1;
              end
          end

        ctrlInit:
          begin
            initState = 1'b1;

            if (keyReady)
              begin
                readyNew         = 1'b1;
                readyWE          = 1'b1;

                ctrlNew = ctrlIdle;
                ctrlWE  = 1'b1;
              end
          end

        ctrlNext:
          begin
            initState = 1'b0;

            if (selReady)
              begin
                readyNew         = 1'b1;
                readyWE          = 1'b1;
               
                ctrlNew = ctrlIdle;
                ctrlWE  = 1'b1;
             end
          end

        default: begin end
      endcase 
    end
endmodule
