`timescale 10ns/1ns

module tb ;

reg clk=0;
reg rst=0;
wire  ifft_valid;
wire signed [47:0] ifft_data;
reg ready=0;
always #5 clk=~clk;
 pss_transmission dut(
		 clk,
		rst,

	 ifft_data,
     ifft_valid,
	 ready
	);


initial begin
	rst=1;
	#15 rst=0;
	ready=1;
end


   localparam SF = 2.0**-21;  
   reg signed [23:0] real_part;
reg signed [23:0] imag_part;
integer file=0;
integer count =0;

initial begin
    file = $fopen("pss_sequence.dat","w");
end
always@(posedge clk) begin
    if ((ifft_valid ) && file!=0 && count < 128) begin
              real_part= ifft_data[23:0];
             imag_part = ifft_data[47:24];
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

endmodule
