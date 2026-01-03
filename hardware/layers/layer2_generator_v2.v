`timescale 1ns / 1ps
// layer2_generator_v2.v
// 256x256 MAC layer, Q5.10 fixed-point, ReLU, saturating to signed 16-bit

module layer2_generator_v2(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [16*256-1:0] flat_input, // flattened inputs, MSB first
    output reg signed [16*256-1:0] flat_output, // flattened outputs, MSB first
    output reg done
);
    localparam N = 256;

    // ROMs for weights and biases (Q5.10 int16)
    (* rom_style = "block" *) reg signed [15:0] weights [0:N*N-1];
    (* rom_style = "block" *) reg signed [15:0] biases [0:N-1];

    initial begin
        // Expect mem files in repo mem/ or absolute path
        $readmemh("d:/WILLGAN/hardware/layers/mem/epoch300_G_l2_W.mem", weights);
        $readmemh("d:/WILLGAN/hardware/layers/mem/epoch300_G_l2_B.mem", biases);
    end

    // State
    reg [8:0] neuron_idx; // 0..255
    reg [8:0] input_idx;  // 0..255
    reg busy;

    // Accumulator width: extend biases (Q5.10) into 48-bit accumulator
    reg signed [47:0] accumulator;
    reg signed [47:0] acc_local;

    // Registers for pipeline to write outputs after processing each neuron
    reg [8:0] neuron_idx_reg;
    reg write_out_reg;

    // temp wires for combinational multiply (use current indices)
    wire signed [15:0] in_val_w;
    wire signed [15:0] w_val_w;
    wire signed [31:0] prod32_w;

    // output value and LeakyReLU (slope = 1/8)
    reg signed [15:0] out_val;
    wire signed [15:0] leaky_out;
    // implement LeakyReLU by arithmetic right shift for negative values
    assign leaky_out = (out_val[15]) ? (out_val >>> 3) : out_val;

    integer i;

    // combinational assignments for current indices
    assign in_val_w = flat_input[(N-1-input_idx)*16 +: 16];
    assign w_val_w = weights[neuron_idx*N + input_idx];
    assign prod32_w = $signed(in_val_w) * $signed(w_val_w);

    always @(posedge clk) begin
        if (rst) begin
            neuron_idx <= 0;
            input_idx <= 0;
            busy <= 0;
            done <= 0;
            accumulator <= 0;
            flat_output <= {16*256{1'b0}};
            neuron_idx_reg <= 0;
            write_out_reg <= 0;
            out_val <= 16'sd0;
        end else begin
            // write output pipeline stage
            if (write_out_reg) begin
                // write leaky-ReLU output
                flat_output[(N-1-neuron_idx_reg)*16 +: 16] <= leaky_out;
                write_out_reg <= 0;
            end

            if (start && !busy) begin
                // start processing (no debug prints)
                busy <= 1;
                done <= 0;
                neuron_idx <= 0;
                input_idx <= 0;
                // initialize accumulator with bias[0], sign-extended into 48 bits
                accumulator <= { {32{biases[0][15]}}, biases[0] };
            end else if (busy) begin
                if (input_idx < N) begin
                    // combinationally read current input and weight using indices
                    // multiply and accumulate (signed)
                    accumulator <= accumulator + (prod32_w >>> 10);
                    input_idx <= input_idx + 1;
                end else begin
                    // finished inputs for this neuron: latch final accumulator and prepare to write
                    // Accumulator is Q5.10, need to saturate and truncate to 16 bits
                    // Use module-scoped temp `acc_local` to avoid SystemVerilog-only declarations
                    // accumulator currently holds integer-summed contributions (prod>>10 summed)
                    acc_local = accumulator;
                    // saturate to signed 16-bit range
                    if (acc_local > 48'sd32767) begin
                        out_val <= 16'sh7FFF;
                    end else if (acc_local < -48'sd32768) begin
                        out_val <= -16'sh8000;
                    end else begin
                        out_val <= acc_local[15:0];
                    end
                        // finished neuron: no debug prints
                    // schedule write
                    neuron_idx_reg <= neuron_idx;
                    write_out_reg <= 1;
                    // advance to next neuron
                    if (neuron_idx < N-1) begin
                        neuron_idx <= neuron_idx + 1;
                        input_idx <= 0;
                        accumulator <= { {32{biases[neuron_idx+1][15]}}, biases[neuron_idx+1] };
                    end else begin
                        // done
                        busy <= 0;
                        done <= 1;
                    end
                end
            end else if (done) begin
                // clear done after one cycle
                done <= 0;
            end
        end
    end
endmodule
