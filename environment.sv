`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor_in.sv"
`include "monitor_out.sv"
`include "scoreboard.sv"

class environment #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);
	
	generator #(ADDR_WIDTH, DATA_WIDTH) gen;
	driver #(ADDR_WIDTH, DATA_WIDTH) drv;
	monitor_in #(ADDR_WIDTH, DATA_WIDTH) mon_in;
	monitor_out #(ADDR_WIDTH, DATA_WIDTH) mon_out;
	scoreboard #(ADDR_WIDTH, DATA_WIDTH) scb;
	
	
	mailbox gen2drv;
	mailbox monin2scb;
	mailbox monout2scb;
	
	virtual inf vinf;
	
	function new(virtual inf vinf);
		this.vinf = vinf;
		gen2drv = new();
		monin2scb = new();
		monout2scb = new();
		
		gen = new(gen2drv);
		drv = new(vinf, gen2drv);
		mon_in = new(vinf, monin2scb);
		mon_out = new(vinf, monout2scb);
		scb = new(monin2scb, monout2scb);
	endfunction
	
  task test();
		$display("starting test at %0t", $time);
		fork
			gen.main();
			drv.main();
			mon_in.main();
			mon_out.main();
			scb.main();
		join_none
		$display("all componets launced at %0t", $time);
	endtask
		
  task post_test();
		wait(gen.ended.triggered);
		$display("time = %0t [Env] Generator finished creating trans.", $time);
		wait(gen.repeat_count == drv.numtransaction);
		$display("time = %0t [Env] Driver finished driving all trans.", $time);
		repeat(5) @(vinf.monitor_out_cb);
		$display("time = %0t [Env] Drain time finished. Checking remaining transactions...", $time);
		if (scb.expected_queue.size() != 0) begin
			$display("time = %0t [Env] WARNING: Scoreboard queue is NOT empty! %0d items remaining.", $time, scb.expected_queue.size());
		end else begin
			$display("time = %0t [Env] Scoreboard queue is empty.", $time);
		end
		
		scb.report();
			$display("############################################################");
			$display("#                   *** TEST PASSED ***                    #");
			$display("############################################################");
		end else begin
			$display("############################################################");
			$display("#                   *** TEST FAILED ***                    #");
			$display("#  errors = %0d | leftover in queue = %0d | checks = %0d", scb.num_error, scb.expected_queue.size(), (scb.num_match + scb.num_error));
			$display("############################################################");
			end
endtask	

  task run();
		test();
		post_test();
		$finish;
	endtask
	
endclass