module Top(
  input start,
  input[127:0] data,
  output[127:0] outData
);

  wire[255:0] key;
  wire[127:0] roundKey;
  wire[31:0] beforeSub, afterSub;


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
    .next(keyReady),
    .round(round),
    .roundKey(roundKey),
    .beforeSub(beforeSub),
    .afterSub(afterSub),
    .block(block),
    .newBlock(newBlock),
    .ready(encReady)
  );

  SubBox SBox(
    .beforeSub(beforeSub),
    .afterSub(afterSub)
  );

endmodule