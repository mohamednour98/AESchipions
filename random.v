module random(
  input reset,
  output reg [63:0] outData
);

  wire feedback;
  wire [63:0]data1;
  assign data1 = (reset) ? {16{4'hf}} : {16{4'ha}};
  assign feedback = data1[63] ^ data1[9] ^ data1[7] ^ data1[5] ^ data1[3] ^ data1[0];

  always @(negedge reset) begin
	 outData <= {data1[62:0], feedback};
  end

endmodule