module TopTB();

  parameter debug     = 0;
  parameter dumpWait = 0;
  parameter halfPeriod = 1;
  parameter period = 2 * halfPeriod;

  reg [31 : 0] cycleCTR;
  reg [31 : 0] errorCTR;
  reg [31 : 0] tcCTR;

  reg tbClk;
  reg tbReset;
  reg mode;

  reg tbInit;
  reg tbNext;
  wire tbReady;
  reg[127:0] tbKey;
  reg[127:0] initVector;

  reg[127:0]  tbBlock;
  wire[127:0] tbResult;


  Top dut(
      .clk(tbClk),
      .reset(tbReset),
      .init(tbInit),
      .next(tbNext),
      .ready(tbReady),
      .mode(mode),
      .inNonceCount(initVector),
      .key(tbKey),
      .data(tbBlock),
      .outData(tbResult)
    );

  always
    begin : clkGen
      #halfPeriod;
      tbClk = !tbClk;
    end

  always
    begin : sysMonitor
      cycleCTR = cycleCTR + 1;
      #(period);
      if (debug)
        begin
          dutState();
        end
    end

  task dutState;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");


      $display("block = 0x%032x", dut.data);
      $display("");
      $display("ready = 0x%01x", dut.ready);
      $display(" result = 0x%032x", dut.outData);
      $display("");
      $display("Encipher state::");
      $display("enc_ctrl = 0x%01x, round_ctr = 0x%01x", dut.encryptor.ctrlReg, dut.encryptor.roundCTRReg);
      $display("outblock = 0x%01x", dut.encryptor.newBlock);
      $display("");
    end
  endtask
/*
  task dumpKeys;
    begin
      $display("State of key memory in DUT:");
      $display("key[00] = 0x%016x", dut.keyGenInst.keyMemory[00]);
      $display("key[01] = 0x%016x", dut.keyGenInst.keyMemory[01]);
      $display("key[02] = 0x%016x", dut.keyGenInst.keyMemory[02]);
      $display("key[03] = 0x%016x", dut.keyGenInst.keyMemory[03]);
      $display("key[04] = 0x%016x", dut.keyGenInst.keyMemory[04]);
      $display("key[05] = 0x%016x", dut.keyGenInst.keyMemory[05]);
      $display("key[06] = 0x%016x", dut.keyGenInst.keyMemory[06]);
      $display("key[07] = 0x%016x", dut.keyGenInst.keyMemory[07]);
      $display("key[08] = 0x%016x", dut.keyGenInst.keyMemory[08]);
      $display("key[09] = 0x%016x", dut.keyGenInst.keyMemory[09]);
      $display("key[10] = 0x%016x", dut.keyGenInst.keyMemory[10]);
      $display("");
    end
  endtask
*/
  task dutReset;
    begin
      $display("*** Toggle reset.");
      tbReset = 0;
      #(2 * period);
      tbReset = 1;
    end
  endtask

  task initSimulation;
    begin
      cycleCTR = 0;
      errorCTR = 0;
      tcCTR    = 0;

      tbClk     = 0;
      tbReset = 1;

      tbInit    = 0;
      tbNext    = 0;
      tbKey     = {4{32'h00000000}};


      tbBlock  = {4{32'h00000000}};
    end
  endtask

  task displayResults;
    begin
      if (errorCTR == 0)
        begin
          $display("*** All %02d test cases completed successfully", tcCTR);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.", tcCTR, errorCTR);
        end
    end
  endtask

  task waitReady;
    begin
      while (!tbReady)
        begin
          #(period);
          if (dumpWait)
            begin
              dutState();
            end
        end
    end
  endtask

  task singleBlockTest(
      input [7 : 0]   tc_number,
      input [127 : 0] key,
      input [127 : 0] block,
      input [127 : 0] expected
    );

    begin
     $display("*** TC %0d CTR mode test started.", tc_number);
     tcCTR = tcCTR + 1;

     tbKey = key;
     tbInit = 1;
     #(2 * period);
     tbInit = 0;
     waitReady();

     $display("Key expansion done");
     $display("");

     tbBlock = block;
     tbNext = 1;
     #(2 * period);
     tbNext = 0;
     waitReady();

     if (tbResult == expected)
       begin
        $display("*** TC %0d successful.", tc_number);
        $display("Key:          0x%032x",dut.key);
        $display("Plaintext:    0x%032x", dut.data);
        $display("Ciphertext:   0x%032x", dut.outData);
        $display("nonce(iv):    0x%032x", dut.nonceIV);
        $display("outblock:     0x%032x", dut.encryptor.newBlock);
        $display("");
       end
     else
       begin
         $display("*** ERROR: TC %0d NOT successful.", tc_number);
         $display("Expected: 0x%032x", expected);
         $display("Got:      0x%032x", tbResult);
         $display("outblock: 0x%01x", dut.encryptor.newBlock);
         $display("");
         errorCTR = errorCTR + 1;
       end
    end
  endtask

  initial
    begin : coreTest
      reg[127:0] key0;
      reg[127:0] key1;
      reg[127:0] key2;
      reg[127:0] key3;

      reg[127:0] nistKey;

      reg[127:0] PT0;
      reg[127:0] PT1;
      reg[127:0] PT2;
      reg[127:0] PT3;

      reg[127:0] nistPT;

      reg[127:0] exp0;
      reg[127:0] exp1;
      reg[127:0] exp2;
      reg[127:0] exp3;

      reg[127:0] nistExp;

      mode = 1'b1;

      initVector = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;

      key0 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
      key1 = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
      key2 = 128'h603deb1015ca71be2b73aef0857d7781;
      key3 = 128'h1f352c073b6108d72d9810a30914dff4;

      nistKey = 128'h2b7e151628aed2a6abf7158809cf4f3c;

      PT0 = 128'h6bc1bee22e409f96e93d7e117393172a;
      PT1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
      PT2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
      PT3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

      nistPT = 128'h6bc1bee22e409f96e93d7e117393172a;

      exp0 = 128'h55f30b0d787661b5711eaaf802d4e073;
      exp1 = 128'he890dea1da4ce22b4d24ee0f73b37c53;
      exp2 = 128'h14d33b87b5f75b2b009fdebfcf86d2db;
      exp3 = 128'h51df6efd98beaacec138db2d773130eb;

      nistExp = 128'h874d6191b620e3261bef6864990db6ce;




      $display("   -= Testbench for aes ctr started =-");
      $display("     ================================");
      $display("");

      initSimulation();
      dutState();
      dutReset();
      dutState();


      $display("ECB 128 bit key tests");
      $display("---------------------");
      if(!mode) begin
        singleBlockTest(
          8'h01,
          key0,
          PT0,
          exp0
        );

        singleBlockTest(
            8'h02,
            key1,
            PT1,
            exp1
          );

        singleBlockTest(
            8'h03,
            key2,
            PT2,
            exp2
          );

        singleBlockTest(
            8'h04,
            key3,
            PT3,
            exp3
          );

          dutReset();

          singleBlockTest(
            8'h05,
            key0,
            exp0,
            PT0
        );

        singleBlockTest(
          8'h06,
          key1,
          exp1,
          PT1
        );

        singleBlockTest(
          8'h07,
          key2,
          exp2,
          PT2
        );

        singleBlockTest(
          8'h08,
          key3,
          exp3,
          PT3
        );
      end
      else begin
        singleBlockTest(
          8'h1,
          nistKey,
          nistPT,
          nistExp
        );
      end

      displayResults();
      $display("");
      $display("*** AES CTR simulation done. ***");
      $finish;
    end
endmodule
