module Top(
  input start,
  input clk,
  input reset,
  input[127:0] data,
  input[127:0] key,
  output encReady,
  output[127:0] outData
);

  wire[127:0] roundKey, block, outEnc;
  wire[31:0] beforeSub, afterSub;
  wire[3:0] round;
  wire[63:0] count;

  reg[127:0] outDataReg;
  reg outDataWE, encNextWE, encNextReg;

  assign outData = outDataReg;
  assign encNext = encNextReg;

  aes_key_mem KeyGen(
    .clk(clk),
    .reset_n(reset),
    .key(key),
    .init(start),
    .round(round),
    .round_key(roundKey),
    .ready(keyReady),
    .sboxw(beforeSub),
    .new_sboxw(afterSub)
  );

  EncryptionBlock Encryptor(
    .clk(clk),
    .reset(reset),
    .next(encNext),
    .round(round),
    .roundKey(roundKey),
    .beforeSub(beforeSub),
    .afterSub(afterSub),
    .block(128'h0),
    .newBlock(outEnc),
    .ready(encReady)
  );

  SubBox SBox(
    .beforeSub(beforeSub),
    .afterSub(afterSub)
  );
/*
  Counter counting(
    .clk(clk),
    .reset(reset),
    .ready(outDataWE),
    .count(count)
  );
*/

  always@(posedge clk) begin
    if(outDataWE)
      outDataReg <= outEnc ^ data;
    if(encNextWE)
      encNextReg <= 1'b1;
  end

  always@(*) begin
    outDataWE = 1'b0;
    encNextWE = 1'b0;
    if(encReady)
      outDataWE = 1'b1;
    if(keyReady)
      encNextWE = 1'b1;
  end

endmodule