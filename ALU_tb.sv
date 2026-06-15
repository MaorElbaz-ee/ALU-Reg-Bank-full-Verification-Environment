`include "interface.sv"
`include "test.sv"
module top;
  	parameter ADDR_WIDTH_TB = 2;
  	parameter DATA_WIDTH_TB = 8;

	logic clk, reset;
  	initial clk = 0;
	
	//clk genetartion
	always #5 clk = ~clk;//100MHz
	
	inf #(ADDR_WIDTH_TB, DATA_WIDTH_TB) intf(clk, reset);
	
	alu #(.ADDR_WIDTH(ADDR_WIDTH_TB), .DATA_WIDTH(DATA_WIDTH_TB)) dut(
			.clk(intf.clk), .reset(intf.reset), .enable(intf.enable), .rd_wr(intf.rd_wr), .addr(intf.addr), .wr_data(intf.wr_data), .rd_data(intf.rd_data), .res_out(intf.res_out)
	);

	test #(ADDR_WIDTH_TB, DATA_WIDTH_TB) t1;
	
	initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
		
	initial begin
		t1 = new(intf);
      $display("starting reset at %0t", $time);
		reset = 1;
		repeat(2) @(posedge clk);
		reset = 0;
      $display("reset done at %0t", $time);
		//-> t1.env.gen.reset_done_gen;
		t1.run();
	end
// to check	, still need to solve reset during test		
endmodule
