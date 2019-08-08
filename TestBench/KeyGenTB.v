


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_aes_key_mem();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 1;
  parameter SHOW_SBOX = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  parameter AES_128_BIT_KEY = 0;
 

  parameter AES_128_NUM_ROUNDS = 10;
 

  parameter AES_DECIPHER = 1'b0;
  parameter AES_ENCIPHER = 1'b1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;
  reg [255 : 0]  tb_key;
  reg            tb_init;
  reg [3 : 0]    tb_round;
  wire [127 : 0] tb_round_key;
  wire           tb_ready;

  wire [31 : 0]  tb_sboxw;
  wire [31 : 0]  tb_new_sboxw;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  aes_key_mem dut(
                  .clk(tb_clk),
                  .reset_n(tb_reset_n),

                  .key(tb_key),
                  .init(tb_init),

                  .round(tb_round),
                  .round_key(tb_round_key),
                  .ready(tb_ready),

                  .sboxw(tb_sboxw),
                  .new_sboxw(tb_new_sboxw)
                 );

  // The DUT requirees Sboxes.
  SubBox sbox(.beforeSub(tb_sboxw), .afterSub(tb_new_sboxw));


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
   /*   $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");
      $display("key       = 0x%032x", dut.key);
      $display("init = 0x%01x, ready = 0x%01x",
               dut.init, dut.ready);
      $display("round     = 0x%02x", dut.round);
      $display("round_key = 0x%016x", dut.round_key);
      $display("");

      $display("Internal states:");
      $display("key_mem_ctrl = 0x%01x, round_key_update = 0x%01x, round_ctr_reg = 0x%01x, rcon_reg = 0x%01x",
               dut.key_mem_ctrl_reg, dut.round_key_update, dut.round_ctr_reg, dut.rcon_reg);

      $display("prev_key0_reg = 0x%016x, prev_key0_new = 0x%016x, prev_key0_we = 0x%01x",
               dut.prev_key0_reg, dut.prev_key0_new, dut.prev_key0_we);
      $display("prev_key1_reg = 0x%016x, prev_key1_new = 0x%016x, prev_key1_we = 0x%01x",
               dut.prev_key1_reg, dut.prev_key1_new, dut.prev_key1_we);

      $display("w0 = 0x%04x, w1 = 0x%04x, w2 = 0x%04x, w3 = 0x%04x",
               dut.round_key_gen.w0, dut.round_key_gen.w1,
               dut.round_key_gen.w2, dut.round_key_gen.w3);
      $display("w4 = 0x%04x, w5 = 0x%04x, w6 = 0x%04x, w7 = 0x%04x",
               dut.round_key_gen.w4, dut.round_key_gen.w5,
               dut.round_key_gen.w6, dut.round_key_gen.w7);
      $display("sboxw = 0x%04x, new_sboxw = 0x%04x, rconw = 0x%04x",
               dut.sboxw, dut.new_sboxw, dut.round_key_gen.rconw);
      $display("tw = 0x%04x, trw = 0x%04x", dut.round_key_gen.tw, dut.round_key_gen.trw);
      $display("key_mem_new = 0x%016x, key_mem_we = 0x%01x",
               dut.key_mem_new, dut.key_mem_we);
      $display("");
*/
      if (SHOW_SBOX)
        begin
       //   $display("Sbox functionality:");
        //  $display("sboxw = 0x%08x", sbox.sboxw);
        //  $display("tmp_new_sbox0 = 0x%02x, tmp_new_sbox1 = 0x%02x, tmp_new_sbox2 = 0x%02x, tmp_new_sbox3",
          //         sbox.tmp_new_sbox0, sbox.tmp_new_sbox1, sbox.tmp_new_sbox2, sbox.tmp_new_sbox3);
        //  $display("new_sboxw = 0x%08x", sbox.new_sboxw);
        //  $display("");
        end
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
      cycle_ctr = 0;
      error_ctr = 0;
      tc_ctr    = 0;

      tb_clk     = 0;
      tb_reset_n = 1;
      tb_key     = {4{32'h00000000}};
      tb_init    = 0;
      tb_round   = 4'h0;
    end
  endtask // init_sim


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
        end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // check_key()
  //
  // Check a given key in the dut key memory against a given
  // expected key.
  //----------------------------------------------------------------
  task check_key(input [3 : 0] key_nr, input [127 : 0] expected);
    begin
      tb_round = key_nr;
      #(CLK_PERIOD);
      if (tb_round_key == expected)
        begin
          $display("** key 0x%01x matched expected round key.", key_nr);
          $display("** Got:      0x%016x **", tb_round_key);
        end
      else
        begin
          $display("** Error: key 0x%01x did not match expected round key. **", key_nr);
          $display("** Expected: 0x%016x **", expected);
          $display("** Got:      0x%016x **", tb_round_key);
          error_ctr = error_ctr + 1;
        end
      $display("");
    end
  endtask // check_key


  //----------------------------------------------------------------
  // test_key_128()
  //
  // Test 128 bit keys. Due to array problems, the result check
  // is fairly ugly.
  //----------------------------------------------------------------
  task test_key_128(input [255 : 0] key,
                    input [127 : 0] expected00,
                    input [127 : 0] expected01,
                    input [127 : 0] expected02,
                    input [127 : 0] expected03,
                    input [127 : 0] expected04,
                    input [127 : 0] expected05,
                    input [127 : 0] expected06,
                    input [127 : 0] expected07,
                    input [127 : 0] expected08,
                    input [127 : 0] expected09,
                    input [127 : 0] expected10
                   );
    begin
      $display("** Testing with 128-bit key 0x%16x", key[127 : 0]);
      $display("");

      tb_key = key;
      tb_init = 1;
      #(2 * CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      check_key(4'h0, expected00);
      check_key(4'h1, expected01);
      check_key(4'h2, expected02);
      check_key(4'h3, expected03);
      check_key(4'h4, expected04);
      check_key(4'h5, expected05);
      check_key(4'h6, expected06);
      check_key(4'h7, expected07);
      check_key(4'h8, expected08);
      check_key(4'h9, expected09);
      check_key(4'ha, expected10);

      tc_ctr = tc_ctr + 1;
    end
  endtask // test_key_128

  

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
  // aes_key_mem_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : aes_key_mem_test
      reg [127 : 0] key128_0;
      reg [127 : 0] key128_1;
      reg [127 : 0] key128_2;
      reg [127 : 0] key128_3;
      reg [127 : 0] nist_key128;
  
      reg [127 : 0] expected_00;
      reg [127 : 0] expected_01;
      reg [127 : 0] expected_02;
      reg [127 : 0] expected_03;
      reg [127 : 0] expected_04;
      reg [127 : 0] expected_05;
      reg [127 : 0] expected_06;
      reg [127 : 0] expected_07;
      reg [127 : 0] expected_08;
      reg [127 : 0] expected_09;
      reg [127 : 0] expected_10;


      $display("   -= Testbench for aes key mem started =-");
      $display("    =====================================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();

      $display("State after reset:");
      dump_dut_state();
      $display("");

      #(100 *CLK_PERIOD);

      // AES-128 test case 1 key and expected values.
      key128_0    = 128'h00000000000000000000000000000000;
      expected_00 = 128'h00000000000000000000000000000000;
      expected_01 = 128'h62636363626363636263636362636363;
      expected_02 = 128'h9b9898c9f9fbfbaa9b9898c9f9fbfbaa;
      expected_03 = 128'h90973450696ccffaf2f457330b0fac99;
      expected_04 = 128'hee06da7b876a1581759e42b27e91ee2b;
      expected_05 = 128'h7f2e2b88f8443e098dda7cbbf34b9290;
      expected_06 = 128'hec614b851425758c99ff09376ab49ba7;
      expected_07 = 128'h217517873550620bacaf6b3cc61bf09b;
      expected_08 = 128'h0ef903333ba9613897060a04511dfa9f;
      expected_09 = 128'hb1d4d8e28a7db9da1d7bb3de4c664941;
      expected_10 = 128'hb4ef5bcb3e92e21123e951cf6f8f188e;

      test_key_128(key128_0,
                   expected_00, expected_01, expected_02, expected_03,
                   expected_04, expected_05, expected_06, expected_07,
                   expected_08, expected_09, expected_10);


      // AES-128 test case 2 key and expected values.
      key128_1    = 128'hffffffffffffffffffffffffffffffff;
      expected_00 = 128'hffffffffffffffffffffffffffffffff;
      expected_01 = 128'he8e9e9e917161616e8e9e9e917161616;
      expected_02 = 128'hadaeae19bab8b80f525151e6454747f0;
      expected_03 = 128'h090e2277b3b69a78e1e7cb9ea4a08c6e;
      expected_04 = 128'he16abd3e52dc2746b33becd8179b60b6;
      expected_05 = 128'he5baf3ceb766d488045d385013c658e6;
      expected_06 = 128'h71d07db3c6b6a93bc2eb916bd12dc98d;
      expected_07 = 128'he90d208d2fbb89b6ed5018dd3c7dd150;
      expected_08 = 128'h96337366b988fad054d8e20d68a5335d;
      expected_09 = 128'h8bf03f233278c5f366a027fe0e0514a3;
      expected_10 = 128'hd60a3588e472f07b82d2d7858cd7c326;

      test_key_128(key128_1,
                   expected_00, expected_01, expected_02, expected_03,
                   expected_04, expected_05, expected_06, expected_07,
                   expected_08, expected_09, expected_10);


      // AES-128 test case 3 key and expected values.
      key128_2    = 128'h000102030405060708090a0b0c0d0e0f;
      expected_00 = 128'h000102030405060708090a0b0c0d0e0f;
      expected_01 = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;
      expected_02 = 128'hb692cf0b643dbdf1be9bc5006830b3fe;
      expected_03 = 128'hb6ff744ed2c2c9bf6c590cbf0469bf41;
      expected_04 = 128'h47f7f7bc95353e03f96c32bcfd058dfd;
      expected_05 = 128'h3caaa3e8a99f9deb50f3af57adf622aa;
      expected_06 = 128'h5e390f7df7a69296a7553dc10aa31f6b;
      expected_07 = 128'h14f9701ae35fe28c440adf4d4ea9c026;
      expected_08 = 128'h47438735a41c65b9e016baf4aebf7ad2;
      expected_09 = 128'h549932d1f08557681093ed9cbe2c974e;
      expected_10 = 128'h13111d7fe3944a17f307a78b4d2b30c5;

      test_key_128(key128_2,
                   expected_00, expected_01, expected_02, expected_03,
                   expected_04, expected_05, expected_06, expected_07,
                   expected_08, expected_09, expected_10);


      // AES-128 test case 4 key and expected values.
      key128_3    = 128'h6920e299a5202a6d656e636869746f2a;
      expected_00 = 128'h6920e299a5202a6d656e636869746f2a;
      expected_01 = 128'hfa8807605fa82d0d3ac64e6553b2214f;
      expected_02 = 128'hcf75838d90ddae80aa1be0e5f9a9c1aa;
      expected_03 = 128'h180d2f1488d0819422cb6171db62a0db;
      expected_04 = 128'hbaed96ad323d173910f67648cb94d693;
      expected_05 = 128'h881b4ab2ba265d8baad02bc36144fd50;
      expected_06 = 128'hb34f195d096944d6a3b96f15c2fd9245;
      expected_07 = 128'ha7007778ae6933ae0dd05cbbcf2dcefe;
      expected_08 = 128'hff8bccf251e2ff5c5c32a3e7931f6d19;
      expected_09 = 128'h24b7182e7555e77229674495ba78298c;
      expected_10 = 128'hae127cdadb479ba8f220df3d4858f6b1;

      test_key_128(key128_3,
                   expected_00, expected_01, expected_02, expected_03,
                   expected_04, expected_05, expected_06, expected_07,
                   expected_08, expected_09, expected_10);


      // NIST AES-128 test case.
      nist_key128 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
      expected_00 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
      expected_01 = 128'ha0fafe1788542cb123a339392a6c7605;
      expected_02 = 128'hf2c295f27a96b9435935807a7359f67f;
      expected_03 = 128'h3d80477d4716fe3e1e237e446d7a883b;
      expected_04 = 128'hef44a541a8525b7fb671253bdb0bad00;
      expected_05 = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
      expected_06 = 128'h6d88a37a110b3efddbf98641ca0093fd;
      expected_07 = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
      expected_08 = 128'head27321b58dbad2312bf5607f8d292f;
      expected_09 = 128'hac7766f319fadc2128d12941575c006e;
      expected_10 = 128'hd014f9a8c9ee2589e13f0cc8b6630ca5;

      $display("Testing the NIST AES-128 key.");
      test_key_128(nist_key128,
                   expected_00, expected_01, expected_02, expected_03,
                   expected_04, expected_05, expected_06, expected_07,
                   expected_08, expected_09, expected_10);


     


      display_test_result();
      $display("");
      $display("*** AES core simulation done. ***");
      $finish;
    end // aes_key_mem_test
endmodule // tb_aes_key_mem

//======================================================================
// EOF tb_aes_key_mem.v
//======================================================================