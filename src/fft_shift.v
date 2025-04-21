module fft_shift(
	input clk,
	input rst,
	input signed[31:0] data_in,
	input valid_in,
	output reg ready_out,

	output signed[31:0] data_out,
	output reg valid_out,
	input ready_in
);
localparam N=128;
localparam M=62;
localparam N_M=N-M-1;

//////INTERNAL SIGNALS/////////////////////
reg [3:0] current_state, next_state;
reg [6:0] write_add;
reg [6:0] read_add;
reg [6:0] rev_addr;
reg signed [31:0] BRAM[N-1:0];
integer i;

/////STATE MACHINE///////////////////////
localparam [3:0]
    LOWER_BAND   = 4'b0000,
    DC			 = 4'b0001,
    UPPER_BAND   = 4'b0010,
    WAIT		 = 4'b0011;

// State register
    always @(posedge clk) begin
        if (rst)
            current_state <= LOWER_BAND;
        else
            current_state <= next_state;
    end
//STATE TRANSITION LOGIC
	always@(*) begin
	case (current_state)
		LOWER_BAND:next_state=(write_add==N-1)?DC:LOWER_BAND;
		DC	  	  :next_state=UPPER_BAND;
		UPPER_BAND:next_state=(write_add==(M>>1)-1) ?WAIT:UPPER_BAND;
		WAIT	  :next_state=(read_add==N-1)?LOWER_BAND:WAIT;
	endcase
end
//NEXT STATE LOGIC
always@(posedge clk) begin
	if (rst) begin
		write_add<=(M>>1)+N_M+1;
		 for (i = 0; i <N ; i = i + 1) begin
			BRAM[i]<=0;
		end
	end
	else if (ready_out && valid_in) begin
		case (current_state)
			LOWER_BAND:begin
					BRAM[write_add]<=data_in;
					write_add<=write_add+1;
				end
			DC	  :write_add<=0;
			UPPER_BAND:begin
					BRAM[write_add]<=data_in;
					write_add<=write_add+1;
				end
			WAIT	  :write_add<=(M>>1)+N_M+1;
		endcase
	   end
	else begin
		write_add<=(write_add==(M>>1))?(M>>1)+N_M+1:write_add;
		end
end
////VALID LOGIC//////////////////////
 always@(posedge clk) begin
  if (rst) begin
		valid_out<=0;
  end
  else if (write_add==M>>1) begin
		valid_out<=1;
  end
  else if (read_add>=N-1) valid_out<=0;
  else valid_out<=valid_out;
  end
//READ ADDRESS LOGIC//////////////////////
  always@(posedge clk) begin
  if (rst) begin
		read_add<=0;
  end
  else if (valid_out && ready_in) begin
  		read_add<=(read_add>=N-1)?0:read_add+1;
  end
  else read_add<=read_add;
  end
///// Bit reversed read address
	always @(*) begin
		rev_addr = {read_add[0],read_add[1],read_add[2],read_add[3],read_add[4],read_add[5],read_add[6]};
	end

  assign data_out=BRAM[rev_addr];
///READY LOGIC//////////////////////
always@(posedge clk) begin
	if (rst) ready_out<=0;
	else if (valid_in) ready_out<=1;
	else ready_out<=0;

end

endmodule