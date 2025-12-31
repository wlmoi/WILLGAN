`timescale 1ns / 1ps
// tb_top_entity.v
// Testbench for top_entity (WGAN Generator Top Level)
`include "top_entity.v"


module tb_top_entity();
    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] data_in;
    wire [15:0] data_out;
    wire valid;
    wire busy;
    // Debug signals
    wire [2:0] state;
    wire [6:0] input_count;
    wire [9:0] output_count;

    // Instantiate DUT
    top_entity dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .valid(valid),
        .busy(busy),
        .state(state),
        .input_count(input_count),
        .output_count(output_count)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz


    // Test stimulus
    integer i;
    integer output_valid_count;
    initial begin
        $display("[INFO] Reset asserted");
        rst_n = 0;
        start = 0;
        data_in = 0;
        #20;
        rst_n = 1;
        $display("[INFO] Reset deasserted");
        #20;
        $display("[INFO] Start pulse");
        start = 1;
        #10;
        start = 0;
        $display("[INFO] Sending 64 input data");
        for (i = 0; i < 64; i = i + 1) begin
            data_in = i;
            $display("[INPUT] Input[%0d] = %h, busy=%b, valid=%b, state=%0d, input_count=%0d, time=%t", i, data_in, busy, valid, state, input_count, $time);
            #10;
        end
        $display("[INFO] Waiting for busy to go low...");
        while (busy == 1) begin
            $display("[WAIT] busy=%b, valid=%b, state=%0d, input_count=%0d, output_count=%0d, time=%t", busy, valid, state, input_count, output_count, $time);
            #1000;
        end
        $display("[INFO] busy is LOW, reading output");
        output_valid_count = 0;
        for (i = 0; i < 784; i = i + 1) begin
            if (valid) begin
                $display("[OUTPUT] Output[%0d] = %h, busy=%b, state=%0d, output_count=%0d, time=%t", i, data_out, busy, state, output_count, $time);
                output_valid_count = output_valid_count + 1;
            end else begin
                if ((i % 50) == 0) $display("[INFO] Waiting valid... i=%0d, busy=%b, state=%0d, output_count=%0d, time=%t", i, busy, state, output_count, $time);
            end
            #10;
        end
        $display("[INFO] Output read done, total valid output: %0d", output_valid_count);
        $display("[INFO] Simulation finished normally");
        $finish;
    end

    // FSM monitoring: tampilkan setiap perubahan state
    reg [2:0] last_state;
    always @(posedge clk) begin
        if (state !== last_state) begin
            $display("[FSM] State changed: state=%0d, busy=%b, valid=%b, input_count=%0d, output_count=%0d, time=%t", state, busy, valid, input_count, output_count, $time);
            last_state <= state;
        end
    end

    // Timeout: stop simulation jika terlalu lama
    initial begin
        #10000000; // 10ms simulasi (10 detik pada timescale 1ns)
        $display("[TIMEOUT] Simulasi dihentikan karena melebihi waktu maksimum pada waktu %t", $time);
        $display("[TIMEOUT] busy=%b, valid=%b, state=%0d, input_count=%0d, output_count=%0d", busy, valid, state, input_count, output_count);
        $finish;
    end
endmodule