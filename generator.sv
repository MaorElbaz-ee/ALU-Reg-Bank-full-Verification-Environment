class generator #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);

	rand transaction #(ADDR_WIDTH, DATA_WIDTH) trans;
	int repeat_count;//num of packet to be created	
	mailbox gen2drv;
	
	function new(mailbox gen2drv);
		this.gen2drv = gen2drv;
	endfunction
	
	event ended;
	event reset_done_gen;
	
	task main();
		//@(reset_done_gen);//to check where i call it
		repeat(repeat_count) begin
			trans = new();
			if(!trans.randomize()) $fatal(0, "Generator :trans randomization failed");
			trans.display("---Generator---");	
			gen2drv.put(trans);
		end
		-> ended;//triger end of the generaion	
	endtask
	
endclass