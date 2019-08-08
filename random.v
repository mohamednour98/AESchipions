module nonce(
  input  clk,
  input  reset,
  input ready,
  output[63:0] outData
);

  reg[63:0] data, dataNew;
  assign outData = dataNew;
  wire feedback = data[63] ^ data[9] ^ data[7] ^ data[5] ^ data[3] ^ data[0];

  always @(posedge clk or negedge reset) begin
    if (~reset) 
      data = {16{4'hf}};
    else begin
      data = {data[62:0], feedback};
      if(ready)
        dataNew = data;
    end
  end

endmodule