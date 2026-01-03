`timescale 1ns / 1ps

`ifndef GENERATOR_V
`define GENERATOR_V

`include "layer1_generator_v2.v"
`include "layer2_generator_v2.v"
`include "layer3_generator_v2.v"
`include "relu.v"

// Full Generator Pipeline
// Input: 64 random noise values (Q5.10)
// Output: 784 image pixels (Q5.10)
// Pipeline: L1(64→256) → ReLU → L2(256→256) → ReLU → L3(256→784)
//
module generator (
    input wire clk,
    input wire rst,
    input wire start,
    // Input: 64 elements × 16 bits = 1024 bits
    input wire signed [16*64-1:0] noise_input,
    // Output: 784 elements × 16 bits = 12544 bits
    output reg signed [16*784-1:0] image_output,
    output reg done
);

    localparam N_NOISE = 64;
    localparam N_L1_OUT = 256;
    localparam N_L2_OUT = 256;
    localparam N_L3_OUT = 784;

    // State machine
    localparam STATE_IDLE = 3'd0;
    localparam STATE_L1 = 3'd1;
    localparam STATE_RELU1 = 3'd2;
    localparam STATE_L2 = 3'd3;
    localparam STATE_RELU2 = 3'd4;
    localparam STATE_L3 = 3'd5;
    localparam STATE_DONE = 3'd6;
    
    reg [2:0] state;
    
    // Layer 1 signals
    reg l1_start;
    wire l1_done;
    wire signed [16*N_L1_OUT-1:0] l1_output;
    
    // ReLU 1 intermediate storage
    reg signed [16*N_L1_OUT-1:0] relu1_output;
    
    // Layer 2 signals
    reg l2_start;
    wire l2_done;
    wire signed [16*N_L2_OUT-1:0] l2_output;
    
    // ReLU 2 intermediate storage
    reg signed [16*N_L2_OUT-1:0] relu2_output;
    
    // Layer 3 signals
    reg l3_start;
    wire l3_done;
    wire signed [16*N_L3_OUT-1:0] l3_output;
    
    // Instantiate Layer 1 (64 → 256)
    layer1_generator_v2 layer1_inst (
        .clk(clk),
        .rst(rst),
        .start(l1_start),
        .flat_input(noise_input),
        .flat_output(l1_output),
        .done(l1_done)
    );
    
    // Instantiate Layer 2 (256 → 256)
    layer2_generator_v2 layer2_inst (
        .clk(clk),
        .rst(rst),
        .start(l2_start),
        .flat_input(relu1_output),
        .flat_output(l2_output),
        .done(l2_done)
    );
    
    // Instantiate Layer 3 (256 → 784)
    layer3_generator_v2 layer3_inst (
        .clk(clk),
        .rst(rst),
        .start(l3_start),
        .flat_input(relu2_output),
        .flat_output(l3_output),
        .done(l3_done)
    );
    
    // ReLU activation function
    function signed [15:0] relu;
        input signed [15:0] x;
        begin
            relu = (x[15] == 1'b1) ? 16'sd0 : x;  // If negative, return 0; else return x
        end
    endfunction
    
    // ReLU counter for processing
    integer relu_idx;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            l1_start <= 1'b0;
            l2_start <= 1'b0;
            l3_start <= 1'b0;
            done <= 1'b0;
            relu1_output <= {(16*N_L1_OUT){1'b0}};
            relu2_output <= {(16*N_L2_OUT){1'b0}};
            image_output <= {(16*N_L3_OUT){1'b0}};
            relu_idx <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        $display("[Generator] Starting pipeline at t=%0t", $time);
                        state <= STATE_L1;
                        l1_start <= 1'b1;
                    end
                end
                
                STATE_L1: begin
                    l1_start <= 1'b0;
                    if (l1_done) begin
                        $display("[Generator] Layer1 complete at t=%0t", $time);
                        state <= STATE_RELU1;
                        relu_idx <= 0;
                    end
                end
                
                STATE_RELU1: begin
                    if (relu_idx < N_L1_OUT) begin
                        // Apply ReLU to each output
                        relu1_output[(N_L1_OUT-1-relu_idx)*16 +: 16] <= 
                            relu(l1_output[(N_L1_OUT-1-relu_idx)*16 +: 16]);
                        relu_idx <= relu_idx + 1;
                    end else begin
                        $display("[Generator] ReLU1 complete at t=%0t", $time);
                        state <= STATE_L2;
                        l2_start <= 1'b1;
                    end
                end
                
                STATE_L2: begin
                    l2_start <= 1'b0;
                    if (l2_done) begin
                        $display("[Generator] Layer2 complete at t=%0t", $time);
                        state <= STATE_RELU2;
                        relu_idx <= 0;
                    end
                end
                
                STATE_RELU2: begin
                    if (relu_idx < N_L2_OUT) begin
                        // Apply ReLU to each output
                        relu2_output[(N_L2_OUT-1-relu_idx)*16 +: 16] <= 
                            relu(l2_output[(N_L2_OUT-1-relu_idx)*16 +: 16]);
                        relu_idx <= relu_idx + 1;
                    end else begin
                        $display("[Generator] ReLU2 complete at t=%0t", $time);
                        state <= STATE_L3;
                        l3_start <= 1'b1;
                    end
                end
                
                STATE_L3: begin
                    l3_start <= 1'b0;
                    if (l3_done) begin
                        $display("[Generator] Layer3 complete at t=%0t", $time);
                        // Copy final output
                        image_output <= l3_output;
                        state <= STATE_DONE;
                        done <= 1'b1;
                    end
                end
                
                STATE_DONE: begin
                    done <= 1'b0;
                    state <= STATE_IDLE;
                end
                
                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule

`endif // GENERATOR_V
