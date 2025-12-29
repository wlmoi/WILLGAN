`timescale 1ns / 1ps

module G_layer2_tb;
	localparam N = 256;

	// Clock / reset / control
	reg clk = 0;
	reg rst = 1;
	reg start = 0;

	// flattened input/output buses (MSB-first for index 0)
	reg signed [16*N-1:0] flat_input;
	wire signed [16*N-1:0] flat_output;
	wire done;

	// Instantiate DUT
	layer2_generator_hw dut (
		.clk(clk),
		.rst(rst),
		.start(start),
		.flat_input(flat_input),
		.flat_output(flat_output),
		.done(done)
	);

	// simple clock
	always #5 clk = ~clk;

	// small helpers
	integer i;
	reg signed [15:0] input_vec [0:N-1];
	reg signed [15:0] output_vec [0:N-1];

	task flatten_input;
	begin
		flat_input = {16*N{1'b0}};
		for (i = 0; i < N; i = i + 1) begin
			flat_input[(N-1-i)*16 +: 16] = input_vec[i];
		end
	end
	endtask

	task unflatten_output;
	begin
		for (i = 0; i < N; i = i + 1) begin
			output_vec[i] = flat_output[(N-1-i)*16 +: 16];
		end
	end
	endtask

	initial begin
		// load input memory (try relative and absolute paths)
		$readmemh("mem/layer1_relu_output.mem", input_vec);
		$readmemh("D:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem", input_vec);

		// reset pulse
		rst = 1; start = 0; flat_input = 0;
		#20; rst = 0; #20;

		// now set the DUT input (do not set it during reset)
		flatten_input();

		// pulse start for one cycle
		@(negedge clk);
		start = 1;
		@(negedge clk);
		start = 0;

		// wait for completion
		wait (done == 1);
		@(negedge clk);

		// capture outputs
		unflatten_output();

		// print concise results
		$display("Layer2 DUT finished. Showing first 16 outputs (pre-ReLU):");
		for (i = 0; i < 16; i = i + 1) $display("out[%0d] = %0d", i, output_vec[i]);

		// dump full array as Python-friendly line (small output)
		$write("hw_out = np.array([");
		for (i = 0; i < N; i = i + 1) begin
			$write("%0d", output_vec[i]);
			if (i != N-1) $write(", ");
		end
		$write("], dtype=np.int16)\n");

		$finish;
	end
endmodule

