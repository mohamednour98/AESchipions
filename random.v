
module nonce(
  input [63:0]counter,
  output[63:0] outData
);

  reg[63:0] data;
  assign outData = data[63:0];
initial 
begin 
data<={8{8'haa}}^counter;
end 
assign outData = data[63:0];
endmodule
