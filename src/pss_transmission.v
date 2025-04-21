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


	// fft shift
	localparam SF = 2.0**-14;  // 11.21 now  #TODO .21
	reg signed [15:0] real_part;
 reg signed [15:0] imag_part;
 integer file=0;
 integer count =0;

 initial begin
	 file = $fopen("fft_shift.dat","w");
 end
 always@(posedge clk) begin
	 if ((valid_in_ifft && ready_in_ifft ) && file!=0 && count < 128) begin
			   real_part= data_in_ifft[15:0];
			  imag_part = data_in_ifft[31:16];
			  if (imag_part<0) begin
				  $fwrite(file,"%f%fi",$itor(real_part*SF),$itor(imag_part*SF));
				  $fwrite(file, "\n");
			  end
			  else begin
				  $fwrite(file,"%f+%fi",$itor(real_part*SF),$itor(imag_part*SF));
				 $fwrite(file, "\n");
			  end
			  count = count +1;
	 end
 end

 // ZC
 reg signed [15:0] real_part_zc;
reg signed [15:0] imag_part_zc;
integer file_zc=0;
integer count_zc =0;

initial begin
  file_zc = $fopen("ZC.dat","w");
end
always@(posedge clk) begin
  if ((valid_in && ready_out ) && file_zc!=0 && count_zc < 63) begin
			real_part_zc= sequnce[15:0];
		   imag_part_zc = sequnce[31:16];
		   if (imag_part_zc<0) begin
			   $fwrite(file_zc,"%f%fi",$itor(real_part_zc*SF),$itor(imag_part_zc*SF));
			   $fwrite(file_zc, "\n");
		   end
		   else begin
			   $fwrite(file_zc,"%f+%fi",$itor(real_part_zc*SF),$itor(imag_part_zc*SF));
			  $fwrite(file_zc, "\n");
		   end
		   count_zc = count_zc +1;
  end
end
endmodule
