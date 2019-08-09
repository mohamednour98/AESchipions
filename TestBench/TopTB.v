module TopTB();

  reg reset, clk, init, next;
  reg[127:0] key, plainText;
  wire[127:0] cipherText;

  Top TopInst(
    .next(next),
    .clk(clk),
    .init(init),
    .reset(reset),
    .data(plainText),
    .key(key),
    .enc_ready(encReady),
    .result(cipherText),
    .ready(ready)
  );

  localparam halfPeriod = 1;
  localparam period = 2 * halfPeriod;
  localparam twicePeriod = 2 * period;

  task restart;
    begin
      $display("Reseting");
      reset = 0;
      #(twicePeriod);
      reset = 1;
    end
  endtask

  task initTest;
    begin
      clk = 0;
      reset = 1;
      next = 0;
      key = 0;
      plainText = 0;
    end
  endtask

  task waitReady;
    begin
      while(!encReady) begin
        #(period);
      end
    end
  endtask

  task test(input[127:0] inKey, inText, inExp);
    begin
      key = inKey;
      init = 1;
      waitReady();
      $display("Key generation done");
      plainText = inText;
      next = 1;
      #(twicePeriod);
      next = 0;
      waitReady();
      #(period);

      if(cipherText == inExp) begin
        $display($time);
        $display("Matching!");
        $display("result = %032x" ,cipherText);
      end
      else begin
        $display($time);
        $display("Expected %032x", inExp);
        $display("Got %032x", cipherText);
      end

    end
  endtask

  always begin
    #(halfPeriod);
    clk = !clk;
  end

  initial begin: mainBlock
    reg[127:0] inData, outDataExp, keyToBe;

    keyToBe = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    inData = 128'h6bc1bee22e409f96e93d7e117393172a;
    outDataExp = 128'h3b3fd92eb72dad20333449f8e83cfb4a;

    initTest();
    restart();
    test(keyToBe, inData, outDataExp);
  end
endmodule