class transaction #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);

  	rand logic rd_wr, enable;
	rand logic [ADDR_WIDTH -1:0] addr;
	rand logic [DATA_WIDTH -1:0] wr_data;
	
	logic [DATA_WIDTH -1:0] rd_data;
	logic [15:0] res_out;	
	
	bit is_reset = 0;
  	constraint addr_range {addr inside {[0:3]};}
	constraint enable_dist { enable dist { 1:= 90, 0:= 10 };}
	constraint execute_bit_dist { 
    (addr == 3 && rd_wr == 0) -> wr_data[0] dist { 1 := 70, 0 := 30 }; 
}
	
	constraint valid_opcode {
    (addr == 2 && rd_wr == 0) -> wr_data[2:0] inside {[3'd0 : 3'd4]};   
    solve addr, rd_wr before wr_data;
}
	int id;
    static int num_tran = 0;

    function new();
        num_tran++;
        id = num_tran;
    endfunction
	
	function void display(string name);
		if (is_reset)
        	$display("time = %0t [%s] !!! RESET PACKET !!!", $time, name);
        $display("------------------------------------");
        $display("- %s [Trans #%0d]", name, id);
        $display("------------------------------------");
        $display("- Addr (Op): %0d, Rd_Wr: %0b", addr, rd_wr);
        $display("- Write Data: %0h", wr_data);
        $display("- Result Out: %0h", res_out);
        $display("------------------------------------");
	endfunction

endclass
