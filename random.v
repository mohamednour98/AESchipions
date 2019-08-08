module nonce(
  input  clk,
  input  reset,
  output[63:0] outData
);

  reg[63:0] data;
  assign outData = data[63:0];
  wire feedback = data[63] ^ data[9] ^ data[7] ^ data[5] ^ data[3] ^ data[0];

  always @(posedge clk or negedge reset) begin
    if (~reset) 
      data <= 64'hffffffffffffffff;
    else begin
      data <= {data[62:0], feedback};
    end
  end

endmodule