class driver #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);
		
	virtual inf vinf;
	mailbox gen2drv;
	
	function new(virtual inf vinf, mailbox gen2drv);
		this.vinf = vinf;
		this.gen2drv = gen2drv;
	endfunction
	
	int numtransaction = 0;
	
	task main();
		forever begin
			vinf.enable  = 1'b0;
			vinf.rd_wr   = 1'b0;
			vinf.wr_data = 0;
			vinf.addr    = 0;
			wait(!vinf.reset);
			@(vinf.driver_cb);
			fork
				begin
					forever begin
						transaction #(ADDR_WIDTH, DATA_WIDTH) trans;
						gen2drv.get(trans);
						vinf.driver_cb.enable  <= trans.enable;
						vinf.driver_cb.rd_wr   <= trans.rd_wr;
						vinf.driver_cb.wr_data <= trans.wr_data;
						vinf.driver_cb.addr    <= trans.addr;
						trans.display("[---Driver---]");
						
						@(vinf.driver_cb);
						if(gen2drv.num() == 0 ) begin
							vinf.driver_cb.enable <= 1'b0;
							@(vinf.driver_cb);
						end
						numtransaction++;
					end
				end
				begin
					@(posedge vinf.reset);
				end
			join_any
			disable fork;
			
			if (vinf.reset) begin
				$display("[Driver] Reset detected! Cleaning ports and restarting loop...", $time);
				vinf.enable  <= 1'b0;
				vinf.rd_wr   <= 1'b0;
				vinf.wr_data <= 0;
				vinf.addr    <= 0;
				wait(!vinf.reset); 
			end
		end
	endtask
endclass