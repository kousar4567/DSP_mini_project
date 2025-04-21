module pss_transmission(
	input clk,
	input rst,

	output signed [48-1:0] data_out,
	output  valid_out,
	input ready_in
);
wire ready_out,valid_in,ready_in_ifft,valid_in_ifft;
wire signed [31:0] sequnce,data_in_ifft;
assign ready_in_ifft=ready_in;
zc_sequence dut(
			. clk(clk),
		   . rst(rst),
		   . ready(ready_out),
		   .valid(valid_in),
		   . seq(sequnce));


	fft_shift fft_shift_dut(
			 .clk(clk),
			 .rst(rst),

			 .data_in(sequnce),
			 .valid_in(valid_in),
			 .ready_out(ready_out),

			 .data_out(data_in_ifft),
			 .valid_out(valid_in_ifft),
			 .ready_in(ready_in_ifft)
	);


	intel_ifft_128 ifft_dut (
		.clk        (clk),        		//   input,   width = 1,    clk.clk
		.rst        (rst),        		//   input,   width = 1,    rst.reset_n
		.validIn    (valid_in_ifft),    //   input,   width = 1,   sink.valid
		.channelIn  (0),  				//   input,   width = 8,       .channel
		.d          ({data_in_ifft[31:16],data_in_ifft[15:0]}),          //   input,  width = 32,       .data
		.validOut   (valid_out),   		//  output,   width = 1, source.valid
		.channelOut (), 				//  output,   width = 8,       .channel
		.q          ({data_out[47:24],data_out[23:0]})           //  output,  width = 54,       .data
	);


	
endmodule
