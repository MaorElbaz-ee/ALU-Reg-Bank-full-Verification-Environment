class scoreboard #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8); // for now only 1 monitor , later to get from 2 seperate monitors

	
	mailbox monin2scb;
	mailbox monout2scb;

    logic [2:0] operation; // 0 -null, 1 add, 2 sub, 3 mul, 4 div	
	
	int num_alu_checks  = 0; // increase per transaction
	int num_read_checks = 0; // increase per read transaction
	
	int num_error = 0, num_match = 0;
	logic [15:0] last_res_out = 0;

	logic [DATA_WIDTH-1:0] reg_bank [2**ADDR_WIDTH];
	transaction #(ADDR_WIDTH, DATA_WIDTH) expected_queue[$];//queue to keep the expected trans from monitor in to monitor out - to sync them
	
	function new(mailbox monin2scb, mailbox monout2scb);
		this.monin2scb  = monin2scb;
		this.monout2scb = monout2scb;
		foreach (reg_bank[i]) reg_bank[i] = 0;
	endfunction
  
  	function logic [7:0] mask_data(input logic [1:0] addr, input logic [7:0] data);
        case(addr)
            2'd2: return data & 8'h07; // 3 low bits for opcode
            2'd3: return data & 8'h01; // only lsb for execute
            default: return data;
        endcase
    endfunction	

	task main();
		fork
			// monitor in
			forever begin
			transaction #(ADDR_WIDTH, DATA_WIDTH) trans_in;
			monin2scb.get(trans_in);
			if(trans_in.is_reset) begin
				$display("[Scoreboard] Reset detected. cleared model and expected_queue at time %0t", $time);
				foreach (reg_bank[i]) reg_bank[i] = 0;				
                expected_queue.delete();// dump the curren transaction
				last_res_out = 0;
				//first_exec_done = 0;
				continue;
			end	
			$display("[Scoreboard Debug] Trans #%0d, addr: %0d, rd_wr: %0b, time = %0t", trans_in.id, trans_in.addr, trans_in.rd_wr, $time);	
			if(!trans_in.rd_wr) begin//if Write
					reg_bank[trans_in.addr] = mask_data(trans_in.addr, trans_in.wr_data);
					if (reg_bank[2'd3][0]) begin //if execute
						//first_exec_done = 1;
						case(reg_bank[2'd2][2:0]) // opertaion
							3'd0: last_res_out = 0;
							3'd1: last_res_out = 16'(reg_bank[2'd0]) + 16'(reg_bank[2'd1]);
							3'd2: last_res_out = 16'(reg_bank[2'd0]) - 16'(reg_bank[2'd1]);
							3'd3: last_res_out = 16'(reg_bank[2'd0]) * 16'(reg_bank[2'd1]);
							3'd4: last_res_out = (reg_bank[2'd1] != 0) ? (16'(reg_bank[2'd0]) / 16'(reg_bank[2'd1])) : 16'hDEAD;
							default: ;
						endcase
					end
				end else begin // Read
					case (trans_in.addr)
							2'd2:    trans_in.rd_data = {5'b0, reg_bank[2'd2][2:0]};
							2'd3:    trans_in.rd_data = {7'b0, reg_bank[2'd3][0]};
							default: trans_in.rd_data = reg_bank[trans_in.addr];
					endcase
				end
				trans_in.res_out = last_res_out;
				expected_queue.push_back(trans_in);
			end
			
			//mointor out
			forever begin
				transaction #(ADDR_WIDTH, DATA_WIDTH) trans_out;
				transaction #(ADDR_WIDTH, DATA_WIDTH) local_exp;
				monout2scb.get(trans_out);
				wait(expected_queue.size() > 0);// waiting for mon_in tran
				local_exp = expected_queue.pop_front();
				//num_transactions++;		
				
				if(local_exp.rd_wr) begin// if read
					logic [7:0] exp_m = mask_data(local_exp.addr, local_exp.rd_data);
					logic [7:0] act_m = mask_data(local_exp.addr, trans_out.rd_data);	
					num_read_checks++;
					if ((act_m === exp_m) && (!$isunknown(act_m))) begin
						$display("PASS: addr %0d Read. Got: %0h", local_exp.addr, trans_out.rd_data);
						num_match++;
                    end else begin
                        $display("FAIL: addr %0d Read. exp: %0h, Got: %0h", local_exp.addr, exp_m, act_m);
						num_error++;
                    end
				end
				num_alu_checks++;
				if (trans_out.res_out === local_exp.res_out) begin
					$display("Trans #%0d ALU PASS. Expected: %0h, Got: %0h at time %0t",
					         local_exp.id, local_exp.res_out, trans_out.res_out, $time);
					num_match++;
				end else begin
					$display("Trans #%0d ALU FAIL. Expected: %0h, Got: %0h at time %0t",
					         local_exp.id, local_exp.res_out, trans_out.res_out, $time);
					num_error++;
				end				
			end
		join
    endtask
	
	function void report();
		int total_checks = num_match + num_error;
		$display("==================== SCOREBOARD REPORT ====================");
		$display(" ALU res_out checks : %0d", num_alu_checks);
		$display(" Read data checks   : %0d", num_read_checks);
		$display(" Total checks       : %0d  (matches: %0d, errors: %0d)",
		         total_checks, num_match, num_error);
		if (total_checks == 0)
			$display(" RESULT : *** FAIL -- no checks were performed ***");
		else if (num_error == 0)
			$display(" RESULT : *** PASS -- all checks matched ***");
		else
			$display(" RESULT : *** FAIL -- %0d mismatch(es) ***", num_error);
		$display("===========================================================");
	endfunction

endclass