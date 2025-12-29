
`timescale 1ns / 1ps
`ifndef LAYER2_GENERATOR_V2_V
`define LAYER2_GENERATOR_V2_V
// Layer 2 Generator (256x256 MAC, Q5.10, ReLU)
module layer2_generator_v2(
    input wire clk,
    input wire rst,
    input wire start,
    input wire signed [16*256-1:0] flat_input, // Q5.10
    output reg signed [16*256-1:0] flat_output, // Q5.10
    output reg done
);
    localparam N = 256;
    // Memory for weights and biases
    (* rom_style = "block" *) reg signed [15:0] weights [0:N*N-1]; // Q5.10
    (* rom_style = "block" *) reg signed [15:0] biases [0:N-1];    // Q5.10
    initial begin
        $readmemh("mem/epoch300_G_l2_W.mem", weights);
        $readmemh("D:/WILLGAN/hardware/layers/mem/epoch300_G_l2_W.mem", weights);
        $readmemh("mem/epoch300_G_l2_B.mem", biases);
        $readmemh("D:/WILLGAN/hardware/layers/mem/epoch300_G_l2_B.mem", biases);
    end

    // State
    reg [8:0] neuron_idx;
    reg [8:0] input_idx;
    reg busy;
    reg signed [47:0] accumulator;
    reg signed [15:0] mac_input, mac_weight;
    reg signed [31:0] mac_product;
    reg signed [47:0] acc_final_reg;
    reg [8:0] neuron_idx_reg;
    reg write_output_reg;
    reg dummy_cycle;

    // Output pipeline
    reg signed [15:0] out_val_reg, relu_out_reg, relu_out_reg2;

    // ReLU
    wire signed [15:0] relu_out;
    assign relu_out = (out_val_reg[15]) ? 16'sd0 : out_val_reg;

    always @(posedge clk) begin
        if (rst) begin
            neuron_idx <= 0;
            input_idx <= 0;
            busy <= 0;
            done <= 0;
            accumulator <= 0;
            flat_output <= 0;
            acc_final_reg <= 0;
            neuron_idx_reg <= 0;
            write_output_reg <= 0;
            dummy_cycle <= 0;
            out_val_reg <= 0;
            relu_out_reg <= 0;
            relu_out_reg2 <= 0;
        end else begin
            // Output pipeline
            // Q5.10 output: saturate to 16 bits, truncate properly, with correct sign extension
            $display("[L2GEN DEBUG] acc_final_reg=%0d (hex=%h)", acc_final_reg, acc_final_reg);
            if (acc_final_reg > 32767 << 10) begin
                out_val_reg <= 16'sh7FFF;
                $display("[L2GEN DEBUG] SATURATE: acc_final_reg > max, out_val_reg=0x%h", 16'sh7FFF);
            end else if (acc_final_reg < -32768 << 10) begin
                out_val_reg <= -16'sh8000;
                $display("[L2GEN DEBUG] SATURATE: acc_final_reg < min, out_val_reg=0x%h", -16'sh8000);
            end else begin
                // Proper sign extension and Q5.10 truncation
                $display("[L2GEN DEBUG] acc_final_reg[25:10]=0x%h, sign-extended=0x%h", acc_final_reg[25:10], {acc_final_reg[25], acc_final_reg[24:10]});
                out_val_reg <= {acc_final_reg[25], acc_final_reg[24:10]};
                $display("[L2GEN DEBUG] out_val_reg assigned=0x%h", {acc_final_reg[25], acc_final_reg[24:10]});
            end
            relu_out_reg <= relu_out;
            relu_out_reg2 <= relu_out_reg;
            if (write_output_reg) begin
                flat_output[(N-1-neuron_idx_reg)*16 +: 16] = relu_out_reg2;
                $display("[L2GEN OUT] neuron=%0d out_val_reg=%0d relu_out_reg=%0d relu_out_reg2=%0d flat_output[%0d]=%0d", neuron_idx_reg, out_val_reg, relu_out_reg, relu_out_reg2, (N-1-neuron_idx_reg), relu_out_reg2);
            end

            // Debug: print first few weights, biases, and input values
            if (start && !busy) begin
                $display("[L2GEN] Bias[0]=%0d (hex=%04h)", biases[0], biases[0]);
                $display("[L2GEN] Weight[0]=%0d (hex=%04h)", weights[0], weights[0]);
                $display("[L2GEN] Weight[1]=%0d (hex=%04h)", weights[1], weights[1]);
                $display("[L2GEN] Weight[255]=%0d (hex=%04h)", weights[255], weights[255]);
                $display("[L2GEN] Input[0]=%0d (hex=%04h)", flat_input[16*255 +: 16], flat_input[16*255 +: 16]);
                $display("[L2GEN] Input[1]=%0d (hex=%04h)", flat_input[16*254 +: 16], flat_input[16*254 +: 16]);
                $display("[L2GEN] Input[255]=%0d (hex=%04h)", flat_input[15:0], flat_input[15:0]);
            end
            if (busy && input_idx < 3) begin
                $display("[L2GEN] neuron_idx=%0d input_idx=%0d mac_input=%0d (hex=%04h) mac_weight=%0d (hex=%04h) acc=%0d", neuron_idx, input_idx, mac_input, mac_input, mac_weight, mac_weight, accumulator);
            end

            if (start && !busy) begin
                busy <= 1;
                done <= 0;
                neuron_idx <= 0;
                input_idx <= 0;
                accumulator <= { {32{biases[0][15]}}, biases[0] };
                acc_final_reg <= 0;
                neuron_idx_reg <= 0;
                write_output_reg <= 0;
                dummy_cycle <= 0;
            end else if (busy) begin
                if (!write_output_reg && !dummy_cycle) begin
                    if (input_idx < N) begin
                        mac_input = flat_input[(N-1-input_idx)*16 +: 16];
                        mac_weight = weights[neuron_idx*N + input_idx];
                        mac_product = mac_input * mac_weight; // Q10.20
                        accumulator <= accumulator + (mac_product >>> 10); // Q5.10
                        input_idx <= input_idx + 1;
                    end else begin
                        dummy_cycle <= 1;
                    end
                end else if (!write_output_reg && dummy_cycle) begin
                    acc_final_reg <= accumulator;
                    neuron_idx_reg <= neuron_idx;
                    write_output_reg <= 1;
                    dummy_cycle <= 0;
                end else begin
                    if (neuron_idx < N-1) begin
                        neuron_idx <= neuron_idx + 1;
                        input_idx <= 0;
                        accumulator <= { {32{biases[neuron_idx+1][15]}}, biases[neuron_idx+1] };
                        write_output_reg <= 0;
                    end else begin
                        busy <= 0;
                        done <= 1;
                        write_output_reg <= 0;
                    end
                end
            end else if (done) begin
                done <= 0;
            end
        end
    end
endmodule
`endif // LAYER2_GENERATOR_V2_V
