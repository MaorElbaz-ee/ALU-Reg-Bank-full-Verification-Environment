interface inf #( 
	parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8
)(
	input logic clk, reset
);
	//logic reset;
	logic enable, rd_wr;
	logic [ADDR_WIDTH -1:0] addr;
	logic [DATA_WIDTH -1:0] wr_data;
	logic [DATA_WIDTH -1:0] rd_data;
	logic [15:0] res_out;
	
	modport dut (input clk, reset, enable, rd_wr, addr, wr_data, output rd_data, res_out);  

	//clocking block
	clocking driver_cb @(posedge clk);//need to add time scale ?
		output enable, addr, wr_data, rd_wr;
		input  rd_data, res_out;
	endclocking
	
	clocking monitor_in_cb @(posedge clk);
		input enable, rd_wr, addr, wr_data, reset;
	endclocking
	
	clocking monitor_out_cb @(posedge clk);
		input res_out, rd_data, reset, enable;
	endclocking
		
	modport driver (clocking driver_cb);
	modport monitor_in (clocking monitor_in_cb);
	modport monitor_out (clocking monitor_out_cb);
	
	property reset_outputs_check;
		@(posedge clk) reset |-> (res_out == 16'b0 && rd_data == {DATA_WIDTH{1'b0}});
	endproperty
	
	property reset_registers_check;
		@(posedge clk) reset |-> (top.dut.regs[0] == {DATA_WIDTH{1'b0}} &&
								  top.dut.regs[1] == {DATA_WIDTH{1'b0}} &&
								  top.dut.regs[2] == {DATA_WIDTH{1'b0}} &&
								  top.dut.regs[3] == {DATA_WIDTH{1'b0}});
	endproperty
	
	a_reset_outputs_check: assert property(reset_outputs_check)
		else $error("Assertion Failed! Outputs not zeroed during reset at time %0t", $time);
	
	a_reset_registers_check: assert property(reset_registers_check)
		else $error("Assertion Failed! Registers not zeroed during reset at time %0t", $time);
	
	property low_enable_comb_check;
		@(posedge clk) disable iff(reset)
		(!enable) |-> ($stable(top.dut.regs[0]) && 
		               $stable(top.dut.regs[1]) && 
		               $stable(top.dut.regs[2]) && 
		               $stable(top.dut.regs[3]) &&
		               $stable(res_out));
	endproperty
	
	property low_enable_rd_data_check;
		@(posedge clk) disable iff(reset)
		(!enable) |=> $stable(rd_data);
	endproperty
	
	a_low_enable_comb_check: assert property(low_enable_comb_check)
		else $error("Assertion Failed! Enable low and comb I/O changed at time %0t", $time);
	
	a_low_enable_rd_data_check: assert property(low_enable_rd_data_check)
		else $error("Assertion Failed! Enable low and rd_data changed at time %0t", $time);
	
	property low_enable_registers_check;
		@(posedge clk) disable iff(reset)
		(!enable) |=> ($stable(top.dut.regs[0]) && $stable(top.dut.regs[1]) && $stable(top.dut.regs[2]) && $stable(top.dut.regs[3]));
	endproperty
	
	a_low_enable_registers_check: assert property(low_enable_registers_check)
		else $error("Assertion Failed! Enable low and Registers changed at time %0t", $time);
		
endinterface//need to change modport - reset is output from driver