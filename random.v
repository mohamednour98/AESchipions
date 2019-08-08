
module nonce(
input clk,
input reset,
  input [63:0]counter,
  output[63:0] outData
);

  reg[63:0] data;
  assign outData = data[63:0];
always@(posedge clk)
begin 
if(!reset)
begin 
data<={8{8'haa}}^counter;
end
else 
data<=data;
end 
assign outData = data[63:0];
endmodule
