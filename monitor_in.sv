class monitor_in #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);//for now only 1 monitor , later to conver into 2 seperate monitors
// if we get reset after read - we assume we need to dump the read trans
	virtual inf vinf;
	mailbox monin2scb;

	function new( virtual inf vinf, mailbox monin2scb);
		this.vinf = vinf;
		this.monin2scb = monin2scb;
	endfunction
	
	task main;
		forever begin
			@(vinf.monitor_in_cb);
			if (vinf.reset) begin
				transaction #(ADDR_WIDTH, DATA_WIDTH) reset_trans;
				reset_trans = new();
				reset_trans.is_reset = 1'b1;// let the scb know that was a reset
				reset_trans.enable   = 1'b0;
				//read_trans = null; 
				$display("[--Monitor In--] Reset detected. Flushing read_trans and notifying Scoreboard.");
				monin2scb.put(reset_trans);
			end	
		
			else begin 
				if(vinf.monitor_in_cb.enable) begin
					transaction #(ADDR_WIDTH, DATA_WIDTH) trans;
					trans = new();
					
					trans.addr = vinf.monitor_in_cb.addr;
					trans.rd_wr = vinf.monitor_in_cb.rd_wr;
					trans.wr_data = vinf.monitor_in_cb.wr_data;
					trans.enable = vinf.monitor_in_cb.enable;
					trans.is_reset = 1'b0;
					
					trans.display("[--Monitor In--]");
					monin2scb.put(trans);

				end	
			end
		end
	endtask
endclass