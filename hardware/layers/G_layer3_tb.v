`timescale 1ns / 1ps

module G_layer3_tb;
    localparam N_IN = 256;
    localparam N_OUT = 784;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg signed [16*N_IN-1:0] flat_input;
    wire signed [16*N_OUT-1:0] flat_output;
    wire done;

    // Instantiate DUT
    layer3_generator_v2 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input),
        .flat_output(flat_output),
        .done(done)
    );

    always #5 clk = ~clk;

    integer i;
    reg signed [15:0] input_vec [0:N_IN-1];
    reg signed [15:0] output_vec [0:N_OUT-1];

    task flatten_input;
    begin
        flat_input = {16*N_IN{1'b0}};
        for (i = 0; i < N_IN; i = i + 1) begin
            flat_input[(N_IN-1-i)*16 +: 16] = input_vec[i];
        end
    end
    endtask

    task unflatten_output;
    begin
        for (i = 0; i < N_OUT; i = i + 1) begin
            output_vec[i] = flat_output[(N_OUT-1-i)*16 +: 16];
        end
    end
    endtask

    initial begin
        // Load input from layer2_relu_output.mem
        $readmemh("mem/layer2_relu_output.mem", input_vec);
        $readmemh("D:/WILLGAN/hardware/layers/mem/layer2_relu_output.mem", input_vec);

        rst = 1; start = 0; flat_input = 0;
        #20; rst = 0; #20;
        flatten_input();
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        wait (done == 1);
        @(negedge clk);
        unflatten_output();

        $display("Layer3 DUT finished. Showing first 16 outputs:");
        for (i = 0; i < 16; i = i + 1) $display("out[%0d] = %0d", i, output_vec[i]);

        $write("hw_out3 = np.array([");
        for (i = 0; i < N_OUT; i = i + 1) begin
            $write("%0d", output_vec[i]);
            if (i != N_OUT-1) $write(", ");
        end
        $write("], dtype=np.int16)\n");

        // Tambahkan delay agar DUT sempat menulis file output.mem
        repeat (5) @(negedge clk);

        $finish;
    end
endmodule
