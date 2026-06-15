module alu #(
	parameter ADDR_WIDTH = 2,// 2 bits for adrres wide
	parameter DATA_WIDTH = 8
)(
	input logic clk, reset, enable, rd_wr, // reset async high active, clk 100MHz// cant be read combine with write (rd_wr)
	input logic [ADDR_WIDTH -1:0] addr,
	input logic [DATA_WIDTH -1:0] wr_data,
		
	output logic [DATA_WIDTH -1:0] rd_data,// output next clk
	output logic [15:0] res_out
);
//if divided by 0 - res_out <= oxdead
//the operation excuted by the operation bit


	logic [DATA_WIDTH-1:0] regs [0:3];//array of registers - 0 = a, 1 = b, 2 = opcode, 3 = result
	typedef enum logic[2:0] {
		IDLE = 3'd0,
		ADD = 3'd1,
		SUB = 3'd2,
		MUL = 3'd3,
		DIV = 3'd4	
	} op_type;
	
	
	op_type opcode;
	assign opcode = op_type'(regs[2][2:0]); // casting to enum from the registers
	
	logic [15:0] res_hold;
	
	always_comb begin
		res_out = res_hold;	
		if(regs[3][0]) begin // if(execute)
			case(opcode)
				IDLE:    res_out = 16'b0;
				ADD:     res_out = regs[0] + regs[1];
				SUB:     res_out = regs[0] - regs[1];
				MUL:     res_out = regs[0] * regs[1];
				DIV:     res_out = (regs[1] != 0) ? (regs[0] / regs[1]) : 16'hDEAD;
				default: res_out = res_hold;
			endcase
		end
	end 


	always_ff @(posedge clk or posedge reset) begin
		if(reset) begin
			regs[0] <= {DATA_WIDTH{1'b0}};
			regs[1] <= {DATA_WIDTH{1'b0}};
			regs[2] <= {DATA_WIDTH{1'b0}};
			regs[3] <= {DATA_WIDTH{1'b0}};
			rd_data <= {DATA_WIDTH{1'b0}};
			res_hold <= 16'b0;
			
		end else begin
			if(enable) begin
				if(!rd_wr) begin // Write
					case(addr)
						2'd0: regs[0] <= wr_data;
						2'd1: regs[1] <= wr_data;
						2'd2: regs[2][2:0] <= wr_data[2:0];
						2'd3: begin
							regs[3][0] <= wr_data[0];// Execute going to 0 — save res_out now while still valid
							if (!wr_data[0])begin
								res_hold <= res_out;
							end
						end
						default: ;
					endcase
					
				end else begin // Read
					case(addr)
						2'd0: rd_data <= regs[0];
						2'd1: rd_data <= regs[1];
						2'd2: rd_data <= {5'b0, regs[2][2:0]};
						2'd3: rd_data <= {7'b0, regs[3][0]};
						default: ;
					endcase
				end
			end
		end
	end
endmodule