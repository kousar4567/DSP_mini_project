module zc_sequence(
							input clk,
							input rst,
							input ready,
							output reg valid,
							output [31:0] seq
			);
localparam N=63;
localparam q=25;
localparam IP_LATENCY=11;

//internal registers
integer count;
reg [3:0] current_state, next_state;
reg [15:0] pi=51463;//Q(2.14)
reg [16:0] two_pi=102926;//Q(3.14)
reg [15:0] read_add;
reg [15:0] write_add;
reg [31:0] pi_q;
reg [44:0] pi_q_m;
reg  [31:0] pi_q_m_N;
reg [31:0] theta_pi;
reg [31:0] theta_pi_2pi;
reg [48:0] theta_wrap;
reg signed [16:0] theta;
reg [13:0] m_temp,m_temp2;
reg en_cordic;
reg [15:0] latency_count;
reg signed [31:0] theta_ram [62:0];
wire  [31:0] seq_reg;
reg [2:0] delay_count;

/////////////////////SEQUENCE GENERATION///////////////////////
// intel cordic ip
cordic cordic_0 (
	.clk    (clk),    //    clk.clk
	.areset (rst), // areset.reset
	.a      (theta),      //      a.a
	.c      (seq_reg[15:0]),      //      c.c
	.s      (seq_reg[31:16])       //      s.s

);

// "Enum" states using localparams
localparam [3:0]
    IDLE    = 4'b0000,
    COMPUTE1   = 4'b0001,
    COMPUTE2    = 4'b0010,
    COMPUTE3    = 4'b0011,
    COMPUTE4	= 4'b0100,
    WAIT=4'b0101;


// State register
    always @(posedge clk) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

// next state logic
    always@(*) begin
	case (current_state)
		IDLE: next_state=COMPUTE1;
		COMPUTE1:next_state=COMPUTE2;
		COMPUTE2:next_state=COMPUTE3;
		COMPUTE3:next_state=COMPUTE4;
		COMPUTE4:next_state=(count==N-1)?WAIT:COMPUTE1;
		WAIT	:next_state=(read_add==N-1)?IDLE:WAIT;
	endcase
end

//next state defination
   always@(posedge clk) begin
	if (rst) begin
				count<=0;
				m_temp<=0;
				m_temp2<=0;
				pi_q_m_N<=0;
				theta<=0;
				theta_wrap<=0;
				en_cordic<=0;
	end
	else begin
		case(current_state)
		IDLE	:begin

				m_temp<=2;
				m_temp2<=4;
				pi_q_m_N<=0;
				theta<=0;
				theta_wrap<=0;
					en_cordic<=0;
			end
		COMPUTE1: begin
				pi_q<=pi*q;//2.14 x 16.0=18.14
				theta_pi<=pi_q_m_N+pi;//18.14 + 2.14 =18.14
				en_cordic<=1;

			end
		COMPUTE2: begin
				pi_q_m<=pi_q*m_temp;//18.14 x 14.0=32.14
				theta_pi_2pi<=theta_pi/two_pi;//18.14 / 3.14 =18.14
			end
		COMPUTE3: begin

				theta_wrap<=theta_pi_2pi*two_pi;//18.14 * 3.14 =21.28
			end
		COMPUTE4 :begin
				pi_q_m_N<=pi_q_m/N;//32.14 / 16.0 =18.14
				theta<=theta_wrap-pi_q_m_N; //21.28  -  18.14= 3.14
				count<=count+1;
				m_temp2<=m_temp2+2;
				m_temp<=m_temp+m_temp2;

			end
		WAIT  :	count<=0;
		endcase
	end
end
/////////////////////// delay and storing//////////////////////
localparam [3:0]
    LATENCY    = 4'b0000,
    DELAY   = 4'b0001,
    STORING    = 4'b0010;
reg [3:0] pr_state, nx_state;

always @(posedge clk) begin
    if (rst)
        pr_state <= LATENCY;
    else
        pr_state <= nx_state;
    end
// next state logic
    always@(*) begin
	case (pr_state)
		LATENCY: nx_state=(latency_count==IP_LATENCY)?(DELAY): LATENCY;
		DELAY:nx_state=(delay_count==2)?STORING:DELAY;
		STORING:nx_state=(write_add==N-1)?LATENCY:DELAY;
		endcase
	end

	always@(posedge clk) begin
	if (rst) begin
		delay_count<=0;
		write_add<=0;
		latency_count<=0;
	end
	else begin
		case(pr_state)
			LATENCY: begin
					latency_count<=en_cordic?latency_count+1:0;
					write_add<=en_cordic?0:write_add;
					end
			DELAY	:delay_count<=delay_count+1;
			STORING : begin
				theta_ram[write_add]<=seq_reg;
				write_add<=write_add+1;
				delay_count<=0;
			end
		endcase
	end

	end

/////////////////////////////////VALID LOGIC//////////////////////

 always@(posedge clk) begin
  if (rst) begin
		valid<=0;
  end
  else if (write_add==N-1) begin
		valid<=1;
  end
  else if (read_add>=N-1) valid<=0;
  else valid<=valid;
  end

/////////////////////////////////READ ADD LOGIC//////////////////////
  always@(posedge clk) begin
  if (rst) begin
		read_add<=0;
  end
  else if (valid && ready) begin
  		read_add<=(read_add>=N-1)?0:read_add+1;
  end
  else read_add<=read_add;
  end

  ///////////////////////// ASSIGNING OUPUT SEQUENCE////////////////////////
  assign seq=theta_ram[read_add];
endmodule
