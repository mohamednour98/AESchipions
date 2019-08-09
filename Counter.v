module Counter(
  input clk,
  input reset,
 
  output[63:0] count
);

  reg[63:0] countReg;
  assign count = countReg;

  always@(posedge clk or negedge reset) begin
    if(~reset) begin
      countReg = 0;
    end
    else countReg = countReg + 1;
  end

endmodule