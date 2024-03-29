
//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_aes_encipher_block1();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 1;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  parameter AES_128_BIT_KEY = 0;
  parameter AES_256_BIT_KEY = 1;

  parameter AES_DECIPHER = 1'b0;
  parameter AES_ENCIPHER = 1'b1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;

  reg            tb_next;
  reg            tb_keylen;
  wire           tb_ready;
  wire [3 : 0]   tb_round;
  wire [127 : 0] tb_round_key;

  wire [31 : 0]  tb_sboxw;
  wire [31 : 0]  tb_new_sboxw;

  reg [127 : 0]  tb_block;
  wire [127 : 0] tb_new_block;

  reg [127 : 0] key_mem [0 : 14];


  //----------------------------------------------------------------
  // Assignments.
  //----------------------------------------------------------------
  assign tb_round_key = key_mem[tb_round];


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  // We need an sbox for the tests.
  SubBox sbox(
                .sboxw(tb_sboxw),
                .new_sboxw(tb_new_sboxw)
               );


  // The device under test.
  EncryptionBlock dut(
                         .clk(tb_clk),
                         .reset(tb_reset_n),

                         .next(tb_next),

                         .round(tb_round),
                         .roundKey(tb_round_key),

                         .sboxw(tb_sboxw),
                         .new_sboxw(tb_new_sboxw),

                         .block(tb_block),
                         .newBlock(tb_new_block),
                         .ready(tb_ready)
                        );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (DEBUG)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Interfaces");
      $display("ready = 0x%01x, next = 0x%01x",
               dut.ready, dut.next);
      $display("block     = 0x%032x", dut.block);
      $display("newBlock = 0x%032x", dut.newBlock);
      $display("");

      $display("Control states");
      $display("round = 0x%01x", dut.round);
      $display("ctrl = 0x%01x, updateType = 0x%01x, sWordCtr = 0x%01x, roundCtr = 0x%01x",
               dut.ctrlReg, dut.updateType, dut.sWordCtrReg, dut.roundCtrReg);
      $display("");

      $display("Internal data values");
      $display("roundKey = 0x%016x", dut.roundKey);
      $display("sboxw = 0x%08x, new_sboxw = 0x%08x", dut.sboxw, dut.new_sboxw);
      $display("block0 = 0x%08x, block1 = 0x%08x, block2 = 0x%08x, block3 = 0x%08x",
               dut.block0Reg, dut.block1Reg, dut.block2Reg, dut.block3Reg);
      $display("");
      $display("oldBlock          = 0x%08x", dut.updateTypeFSM.oldBlock);
      $display("shiftRowsBlock    = 0x%08x", dut.updateTypeFSM.shiftRowsBlock);
      $display("mixColumnsBlock   = 0x%08x", dut.updateTypeFSM.mixColumnsBlock);
      $display("addKeyInitBlock  = 0x%08x", dut.updateTypeFSM.addKeyInitBlock);
      $display("addKeyMainBlock  = 0x%08x", dut.updateTypeFSM.addKeyMainBlock);
      $display("addKeyFinalBlock = 0x%08x", dut.updateTypeFSM.addKeyFinalBlock);
      $display("block0New = 0x%08x, block1New = 0x%08x, block2New = 0x%08x, block3New = 0x%08x",
               dut.blockNew[127 : 096], dut.blockNew[095 : 064],
               dut.blockNew[063 : 032], dut.blockNew[031 : 000]);
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr    = 0;
      error_ctr    = 0;
      tc_ctr       = 0;

      tb_clk       = 0;
      tb_reset_n   = 1;

      tb_next      = 0;
      tb_keylen    = 0;

      tb_block     = {4{32'h00000000}};
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag in the dut to be set.
  //
  // Note: It is the callers responsibility to call the function
  // when the dut is actively processing and will in fact at some
  // point set the flag.
  //----------------------------------------------------------------
  task wait_ready;
    begin
      while (!tb_ready)
        begin
          #(CLK_PERIOD);
          if (DUMP_WAIT)
            begin
              dump_dut_state();
            end
        end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // test_ecb_enc()
  //
  // Perform ECB mode encryption test.
  //----------------------------------------------------------------
  task test_ecb_enc(
                    input           key_length,
                    input [127 : 0] block,
                    input [127 : 0] expected);
   begin
     $display("*** TC %0d ECB mode test started.", tc_ctr);

     // Init the cipher with the given key and length.
     tb_keylen = key_length;

     // Perform encipher operation on the block.
     tb_block = block;
     tb_next = 1;
     #(2 * CLK_PERIOD);
     tb_next = 0;
     #(2 * CLK_PERIOD);

     wait_ready();

     if (tb_new_block == expected)
       begin
         $display("*** TC %0d successful.", tc_ctr);
         $display("");
       end
     else
       begin
         $display("*** ERROR: TC %0d NOT successful.", tc_ctr);
         $display("Expected: 0x%032x", expected);
         $display("Got:      0x%032x", tb_new_block);
         $display("");

         error_ctr = error_ctr + 1;
       end
     tc_ctr = tc_ctr + 1;
   end
  endtask // ecb_mode_single_block_test


  //----------------------------------------------------------------
  // tb_aes_encipher_block
  // The main test functionality.
  //
  // Test cases taken from NIST SP 800-38A:
  // http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
  //----------------------------------------------------------------
  initial
    begin : tb_aes_encipher_block
      reg [127 : 0] nist_plaintext0;
      reg [127 : 0] nist_plaintext1;
      reg [127 : 0] nist_plaintext2;
      reg [127 : 0] nist_plaintext3;

      reg [127 : 0] nist_ecb_128_enc_expected0;
      reg [127 : 0] nist_ecb_128_enc_expected1;
      reg [127 : 0] nist_ecb_128_enc_expected2;
      reg [127 : 0] nist_ecb_128_enc_expected3;
/*
      reg [127 : 0] nist_ecb_256_enc_expected0;
      reg [127 : 0] nist_ecb_256_enc_expected1;
      reg [127 : 0] nist_ecb_256_enc_expected2;
      reg [127 : 0] nist_ecb_256_enc_expected3;
*/
      nist_plaintext0 = 128'h6bc1bee22e409f96e93d7e117393172a;
      nist_plaintext1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
      nist_plaintext2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
      nist_plaintext3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

      nist_ecb_128_enc_expected0 = 128'h3ad77bb40d7a3660a89ecaf32466ef97;
      nist_ecb_128_enc_expected1 = 128'hf5d3d58503b9699de785895a96fdbaaf;
      nist_ecb_128_enc_expected2 = 128'h43b1cd7f598ece23881b00e3ed030688;
      nist_ecb_128_enc_expected3 = 128'h7b0c785e27e8ad3f8223207104725dd4;
/*
      nist_ecb_256_enc_expected0 = 255'hf3eed1bdb5d2a03c064b5a7e3db181f8;
      nist_ecb_256_enc_expected1 = 255'h591ccb10d410ed26dc5ba74a31362870;
      nist_ecb_256_enc_expected2 = 255'hb6ed21b99ca6f4f9f153e7b1beafed1d;
      nist_ecb_256_enc_expected3 = 255'h23304b7a39f9f3ff067d8d8f9e24ecc7;
*/

      $display("   -= Testbench for aes encipher block started =-");
      $display("     ============================================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();


      // NIST 128 bit ECB tests.
      key_mem[00] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
      key_mem[01] = 128'ha0fafe1788542cb123a339392a6c7605;
      key_mem[02] = 128'hf2c295f27a96b9435935807a7359f67f;
      key_mem[03] = 128'h3d80477d4716fe3e1e237e446d7a883b;
      key_mem[04] = 128'hef44a541a8525b7fb671253bdb0bad00;
      key_mem[05] = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
      key_mem[06] = 128'h6d88a37a110b3efddbf98641ca0093fd;
      key_mem[07] = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
      key_mem[08] = 128'head27321b58dbad2312bf5607f8d292f;
      key_mem[09] = 128'hac7766f319fadc2128d12941575c006e;
      key_mem[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
      key_mem[11] = 128'h00000000000000000000000000000000;
      key_mem[12] = 128'h00000000000000000000000000000000;
      key_mem[13] = 128'h00000000000000000000000000000000;
      key_mem[14] = 128'h00000000000000000000000000000000;

      test_ecb_enc(AES_128_BIT_KEY, nist_plaintext0, nist_ecb_128_enc_expected0);
      //test_ecb_enc(AES_128_BIT_KEY, nist_plaintext1, nist_ecb_128_enc_expected1);
      //test_ecb_enc(AES_128_BIT_KEY, nist_plaintext2, nist_ecb_128_enc_expected2);
      //test_ecb_enc(AES_128_BIT_KEY, nist_plaintext3, nist_ecb_128_enc_expected3);

/*
      // NIST 256 bit ECB tests.
      key_mem[00] = 128'h603deb1015ca71be2b73aef0857d7781;
      key_mem[01] = 128'h1f352c073b6108d72d9810a30914dff4;
      key_mem[02] = 128'h9ba354118e6925afa51a8b5f2067fcde;
      key_mem[03] = 128'ha8b09c1a93d194cdbe49846eb75d5b9a;
      key_mem[04] = 128'hd59aecb85bf3c917fee94248de8ebe96;
      key_mem[05] = 128'hb5a9328a2678a647983122292f6c79b3;
      key_mem[06] = 128'h812c81addadf48ba24360af2fab8b464;
      key_mem[07] = 128'h98c5bfc9bebd198e268c3ba709e04214;
      key_mem[08] = 128'h68007bacb2df331696e939e46c518d80;
      key_mem[09] = 128'hc814e20476a9fb8a5025c02d59c58239;
      key_mem[10] = 128'hde1369676ccc5a71fa2563959674ee15;
      key_mem[11] = 128'h5886ca5d2e2f31d77e0af1fa27cf73c3;
      key_mem[12] = 128'h749c47ab18501ddae2757e4f7401905a;
      key_mem[13] = 128'hcafaaae3e4d59b349adf6acebd10190d;
      key_mem[14] = 128'hfe4890d1e6188d0b046df344706c631e;

      test_ecb_enc(AES_256_BIT_KEY, nist_plaintext0, nist_ecb_256_enc_expected0);
      test_ecb_enc(AES_256_BIT_KEY, nist_plaintext1, nist_ecb_256_enc_expected1);
      test_ecb_enc(AES_256_BIT_KEY, nist_plaintext2, nist_ecb_256_enc_expected2);
      test_ecb_enc(AES_256_BIT_KEY, nist_plaintext3, nist_ecb_256_enc_expected3);
*/

      display_test_result();
      $display("");
      $display("*** AES encipher block module simulation done. ***");
      $finish;
    end // aes_core_test
endmodule // tb_aes_encipher_block

//======================================================================
// EOF tb_aes_encipher_block.v
//======================================================================
