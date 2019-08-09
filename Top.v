module Top(
  input next,
  input clk,
  input init,
  input reset,
  input[127:0] data,
  input[127:0] key,
  output enc_ready,
  output[127:0] result,
  output wire ready
);
  localparam CTRL_IDLE  = 2'h0;
  localparam CTRL_INIT  = 2'h1;
  localparam CTRL_NEXT  = 2'h2;


  wire[127:0] roundKey, block, outEnc;
  wire[31:0] beforeSub, afterSub;
  wire[3:0] round;
  wire[63:0] count;
  wire [63:0] nonce;

  wire [127 : 0] round_key;
  wire           key_ready;


  wire [3 : 0]   enc_round_nr;
  wire [127 : 0] enc_new_block;
  wire [31 : 0]  enc_sboxw;

 
  wire [3 : 0]   dec_round_nr;
  wire [127 : 0] dec_new_block;
  wire           dec_ready;

  wire [31 : 0]  keymem_sboxw;
  wire [31 : 0]  new_sboxw;

  reg            enc_next;
  reg [31 : 0]   muxed_sboxw;	
  reg            dec_next;
  reg            init_state;
  reg [127 : 0]  muxed_new_block;
  reg [3 : 0]    muxed_round_nr;
  reg            muxed_ready;
  reg [1 : 0] aes_core_ctrl_reg;
  reg [1 : 0] aes_core_ctrl_new;
  reg         aes_core_ctrl_we;

  reg         ready_reg;
  reg         ready_new;
  reg         ready_we;

  assign ready        = ready_reg;
  assign result       = muxed_new_block;

  aes_key_mem KeyGen(
    .clk(clk),
    .reset_n(reset),
    .key(key),
    .init(init),
    .round(muxed_round_nr),
    .round_key(round_key),
    .ready(key_ready),
    .sboxw(keymem_sboxw),
    .new_sboxw(new_sboxw)
  );

  EncryptionBlock Encryptor(
    .clk(clk),
    .reset(reset),
    .next(enc_next),
    .round(enc_round_nr),
    .roundKey(round_key),
    .sboxw(enc_sboxw),
    .new_sboxw(new_sboxw),
    .block({nonce[63:0],count[63:0]}),
    .newBlock(enc_new_block),
    .ready(enc_ready)
  );

  SubBox  sbox_inst(
	.sboxw(muxed_sboxw), 
	.new_sboxw(new_sboxw)
  );

  Counter counting(
    .clk(start),
    .reset(reset),
    .count(count)
  );
  random fornonce(
    .reset(reset),
    .outData(nonce)
  );

  always @*
    begin : sbox_mux
      if (init_state)
        begin
          muxed_sboxw = keymem_sboxw;
        end
      else
        begin
          muxed_sboxw = enc_sboxw;
        end
    end // sbox_mux


  always @ (posedge clk or negedge reset)
    begin: reg_update
      if (!reset)
        begin
          ready_reg         <= 1'b1;
          aes_core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (aes_core_ctrl_we)
            aes_core_ctrl_reg <= aes_core_ctrl_new;

          if(enc_ready)
            muxed_new_block <= data ^ enc_new_block;
        end
    end // reg_update
  always @*
    begin : encdec_mux
      enc_next = 1'b0;
      dec_next = 1'b0;

      // Encipher operations
      enc_next        = next;
      muxed_round_nr  = enc_round_nr;
      muxed_new_block = enc_new_block;
      muxed_ready     = enc_ready;
     
    end // encdec_mux

    always @*
    begin : aes_core_ctrl
      init_state        = 1'b0;
      ready_new         = 1'b0;
      ready_we          = 1'b0;
     
     
      aes_core_ctrl_new = CTRL_IDLE;
      aes_core_ctrl_we  = 1'b0;

      case (aes_core_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                init_state        = 1'b1;
                ready_new         = 1'b0;
                ready_we          = 1'b1;
            
                
                aes_core_ctrl_new = CTRL_INIT;
                aes_core_ctrl_we  = 1'b1;
              end
            else if (start)
              begin
                init_state        = 1'b0;
                ready_new         = 1'b0;
                ready_we          = 1'b1;
               
                aes_core_ctrl_new = CTRL_NEXT;
                aes_core_ctrl_we  = 1'b1;
              end
          end

        CTRL_INIT:
          begin
            init_state = 1'b1;

            if (key_ready)
              begin
                ready_new         = 1'b1;
                ready_we          = 1'b1;
                aes_core_ctrl_new = CTRL_IDLE;
                aes_core_ctrl_we  = 1'b1;
              end
          end

        CTRL_NEXT:
          begin
            init_state = 1'b0;

            if (muxed_ready)
              begin
                ready_new         = 1'b1;
                ready_we          = 1'b1;
               
                aes_core_ctrl_new = CTRL_IDLE;
                aes_core_ctrl_we  = 1'b1;
             end
          end

        default:
          begin

          end
      endcase // case (aes_core_ctrl_reg)

    end // aes_core_ctrl
     

   
endmodule