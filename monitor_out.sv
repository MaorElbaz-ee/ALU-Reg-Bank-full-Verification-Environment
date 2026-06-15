class monitor_out #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);//for now only 1 monitor , later to conver into 2 seperate monitors
// if we get reset after read - we assume we need to dump the read trans
	virtual inf vinf;
	mailbox monout2scb;
			
	function new( virtual inf vinf, mailbox monout2scb);
		this.vinf = vinf;
		this.monout2scb = monout2scb;
	endfunction
	
	task main;	
      	logic prev_enable = 0;

		forever begin
			@(vinf.monitor_out_cb);
			if (vinf.reset) begin
				prev_enable = 0;
				continue;
			end

				if (prev_enable) begin
					transaction #(ADDR_WIDTH, DATA_WIDTH) trans;
					trans = new();
					trans.enable = vinf.monitor_out_cb.enable;
					trans.rd_data = vinf.monitor_out_cb.rd_data;
					trans.res_out = vinf.monitor_out_cb.res_out;
					trans.is_reset = 1'b0;
					$display("[--Monitor Out--] | Time: %0t | Rd_Data: 0x%0h | Res_Out: 0x%0h | current enable = %0b", $time, trans.rd_data, trans.res_out, trans.enable);	
					monout2scb.put(trans);
          	end
			prev_enable = vinf.monitor_out_cb.enable;
		end
	endtask
endclass
