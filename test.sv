`include "environment.sv"

class test #(parameter ADDR_WIDTH = 2, parameter DATA_WIDTH = 8);
	
	environment #(ADDR_WIDTH, DATA_WIDTH) env;
	virtual inf vinf;

  function new(virtual inf vinf);
		this.vinf = vinf;
		env = new(vinf);
	endfunction
	
	task run();
		env.gen.repeat_count = 80;
		env.run();
	endtask
endclass
