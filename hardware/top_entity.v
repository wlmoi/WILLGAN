`timescale 1ns / 1ps

// top_entity.v
// Top-level WGAN Generator using unified generator module
// Simplified architecture with serial input/output interface

// For simulation: include generator module and dependencies
`ifndef SYNTHESIS
    `include "layers/generator.v"
`endif

module top_entity (
    input  wire        clk,
    input  wire        rst_n,        // Active-low reset
    input  wire        start,        // Start generation pulse
    input  wire [15:0] data_in,      // Serial input data (64 samples)
    output wire [15:0] data_out,     // Serial output data (784 pixels)
    output wire        valid,        // Output valid signal
    output wire        busy,         // Busy processing
    output reg  [2:0]  state,        // Debug: FSM state
    output reg  [6:0]  input_count,  // Debug: input counter (0-63)
    output reg  [9:0]  output_count  // Debug: output counter (0-783)
);

    // Internal reset (active-high)
    wire rst;
    assign rst = ~rst_n;

    // Generator signals
    reg gen_start;
    wire gen_done;
    reg signed [16*64-1:0] noise_buffer;
    wire signed [16*784-1:0] image_buffer;

    // Instantiate unified generator
    generator gen_inst (
        .clk(clk),
        .rst(rst),
        .start(gen_start),
        .noise_input(noise_buffer),
        .image_output(image_buffer),
        .done(gen_done)
    );

    // Serial output register
    reg [15:0] output_pixel;
    
    // FSM States
    // State 0: IDLE - Wait for start
    // State 1: INPUT_LOAD - Load 64 noise samples serially
    // State 2: GENERATE - Run full generator pipeline
    // State 3: OUTPUT_READ - Output 784 pixels serially
    // State 4: DONE - Complete, return to IDLE

    always @(posedge clk) begin
        if (rst) begin
            state <= 3'd0;
            input_count <= 7'd0;
            output_count <= 10'd0;
            gen_start <= 1'b0;
            noise_buffer <= {1024{1'b0}};
            output_pixel <= 16'd0;
        end else begin
            case (state)
                3'd0: begin  // IDLE - Wait for start pulse
                    input_count <= 7'd0;
                    output_count <= 10'd0;
                    gen_start <= 1'b0;
                    if (start) begin
                        state <= 3'd1;
                    end
                end
                
                3'd1: begin  // INPUT_LOAD - Load 64 noise samples
                    // Load data_in into noise_buffer (MSB-first indexing)
                    noise_buffer[(63 - input_count)*16 +: 16] <= data_in;
                    input_count <= input_count + 7'd1;
                    
                    if (input_count == 7'd63) begin
                        state <= 3'd2;
                        gen_start <= 1'b1;
                    end
                end
                
                3'd2: begin  // GENERATE - Run generator pipeline
                    gen_start <= 1'b0;
                    if (gen_done) begin
                        state <= 3'd3;
                        output_count <= 10'd0;
                        // Preload first output pixel
                        output_pixel <= image_buffer[(783 - 0)*16 +: 16];
                    end
                end
                
                3'd3: begin  // OUTPUT_READ - Stream out 784 pixels
                    output_count <= output_count + 10'd1;
                    
                    if (output_count < 10'd783) begin
                        // Update output pixel for next cycle
                        output_pixel <= image_buffer[(783 - output_count - 1)*16 +: 16];
                    end else begin
                        // All pixels output, done
                        state <= 3'd4;
                    end
                end
                
                3'd4: begin  // DONE - Return to IDLE
                    state <= 3'd0;
                end
                
                default: state <= 3'd0;
            endcase
        end
    end

    // Output assignments
    assign data_out = output_pixel;
    assign valid = (state == 3'd3);  // Valid during output streaming
    assign busy = (state != 3'd0 && state != 3'd4);  // Busy when processing

endmodule
