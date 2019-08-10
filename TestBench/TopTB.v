module TopTB();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;
  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  parameter AES_128_BIT_KEY = 0;



  parameter AES_ENCIPHER = 1'b1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;
 
  reg            tb_init;
  reg            tb_next;
  wire           tb_ready;
  reg [127 : 0]  tb_key;

  reg [127 : 0]  tb_block;
  wire [127 : 0] tb_result;
 


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  Top dut(
               .clk(tb_clk),
               .reset(tb_reset_n),
               .init(tb_init),
               .next(tb_next),
               .ready(tb_ready),
               .key(tb_key),
               .data(tb_block),
               .outData(tb_result)
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
      $display("Inputs and outputs:");
    
     
      $display("block  = 0x%032x", dut.data);
      $display("");
      $display("ready        = 0x%01x", dut.ready);
      $display(" result = 0x%032x",
                dut.outData);
      $display("");
      $display("Encipher state::");
      $display("enc_ctrl = 0x%01x, round_ctr = 0x%01x",
               dut.Encryptor.enc_ctrl_reg, dut.Encryptor.round_ctr_reg);
      $display("outblock        = 0x%01x", dut.Encryptor.new_block);
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // dump_keys()
  //
  // Dump the keys in the key memory of the dut.
  //----------------------------------------------------------------
  task dump_keys;
    begin
      $display("State of key memory in DUT:");
      $display("key[00] = 0x%016x", dut.KeyGen.key_mem[00]);
      $display("key[01] = 0x%016x", dut.KeyGen.key_mem[01]);
      $display("key[02] = 0x%016x", dut.KeyGen.key_mem[02]);
      $display("key[03] = 0x%016x", dut.KeyGen.key_mem[03]);
      $display("key[04] = 0x%016x", dut.KeyGen.key_mem[04]);
      $display("key[05] = 0x%016x", dut.KeyGen.key_mem[05]);
      $display("key[06] = 0x%016x", dut.KeyGen.key_mem[06]);
      $display("key[07] = 0x%016x", dut.KeyGen.key_mem[07]);
      $display("key[08] = 0x%016x", dut.KeyGen.key_mem[08]);
      $display("key[09] = 0x%016x", dut.KeyGen.key_mem[09]);
      $display("key[10] = 0x%016x", dut.KeyGen.key_mem[10]);
      $display("");
    end
  endtask // dump_keys


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
  
      tb_init    = 0;
      tb_next    = 0;
      tb_key     = {4{32'h00000000}};
     

      tb_block  = {4{32'h00000000}};
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
  // ecb_mode_single_block_test()
  //
  // Perform ECB mode encryption or decryption single block test.
  //----------------------------------------------------------------
  task ecb_mode_single_block_test(input [7 : 0]   tc_number,
                                  input [127 : 0] key,
                                  input [127 : 0] block,
                                  input [127 : 0] expected);
   begin
     $display("*** TC %0d CTR mode test started.", tc_number);
     tc_ctr = tc_ctr + 1;

     // Init the cipher with the given key and length.
     tb_key = key;
     tb_init = 1;
     #(2 * CLK_PERIOD);
     tb_init = 0;
     wait_ready();

     $display("Key expansion done");
     $display("");

   //  dump_keys();


     // Perform encipher och decipher operation on the block.
     tb_block = block;
     tb_next = 1;
     #(2 * CLK_PERIOD);
     tb_next = 0;
     wait_ready();

     if (tb_result == expected)
       begin
         $display("*** TC %0d successful.", tc_number);
	 $display("Key:          0x%032x",dut.key);
	 $display("Plaintext:    0x%032x", dut.data);
         $display("Ciphertext:   0x%032x", dut.outData);
         $display("nonce(iv):    0x%032x", dut.nonceIv);
         $display("outblock:     0x%032x", dut.Encryptor.new_block);
        
         $display("");
       end
     else
       begin
         $display("*** ERROR: TC %0d NOT successful.", tc_number);
         $display("Expected: 0x%032x", expected);
         $display("Got:      0x%032x", tb_result);
         $display("outblock: 0x%01x", dut.Encryptor.new_block);
         $display("");

         error_ctr = error_ctr + 1;
       end
   end
  endtask // ctr_mode_single_block_test


  //----------------------------------------------------------------
  // aes_core_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : aes_core_test
      reg [127 : 0] nist_aes128_key0;
      reg [127 : 0] nist_aes128_key1;
      reg [127 : 0] nist_aes128_key2;
      reg [127 : 0] nist_aes128_key3;

      reg [127 : 0] nist_plaintext0;
      reg [127 : 0] nist_plaintext1;
      reg [127 : 0] nist_plaintext2;
      reg [127 : 0] nist_plaintext3;

      reg [127 : 0] nist_ctr_128_enc_expected0;
      reg [127 : 0] nist_ctr_128_enc_expected1;
      reg [127 : 0] nist_ctr_128_enc_expected2;
      reg [127 : 0] nist_ctr_128_enc_expected3;

  
      nist_aes128_key0 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
      nist_aes128_key1 = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
      nist_aes128_key2 = 128'h603deb1015ca71be2b73aef0857d7781;
      nist_aes128_key3 = 128'h1f352c073b6108d72d9810a30914dff4;      

      nist_plaintext0 = 128'h6bc1bee22e409f96e93d7e117393172a;
      nist_plaintext1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
      nist_plaintext2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
      nist_plaintext3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

      nist_ctr_128_enc_expected0 = 128'h55f30b0d787661b5711eaaf802d4e073;
      nist_ctr_128_enc_expected1 = 128'he890dea1da4ce22b4d24ee0f73b37c53;
      nist_ctr_128_enc_expected2 = 128'h14d33b87b5f75b2b009fdebfcf86d2db;
      nist_ctr_128_enc_expected3 = 128'h51df6efd98beaacec138db2d773130eb;




      $display("   -= Testbench for aes ctr started =-");
      $display("     ================================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();


      $display("ECB 128 bit key tests");
      $display("---------------------");
      ecb_mode_single_block_test(8'h01, nist_aes128_key0,
                                 nist_plaintext0, nist_ctr_128_enc_expected0);

     ecb_mode_single_block_test(8'h02, nist_aes128_key1,
                                nist_plaintext1, nist_ctr_128_enc_expected1);

     ecb_mode_single_block_test(8'h03, nist_aes128_key2,
                                nist_plaintext2, nist_ctr_128_enc_expected2);

     ecb_mode_single_block_test(8'h04, nist_aes128_key3,
                                nist_plaintext3, nist_ctr_128_enc_expected3);




  
      


      display_test_result();
      $display("");
      $display("*** AES CTR simulation done. ***");
      $finish;
    end // aes_top_test
endmodule // TopTB
