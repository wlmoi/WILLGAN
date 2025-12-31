
`timescale 1ns / 1ps
// top_entity.v
// Top-level WGAN Generator (control+datapath), include all modules and .mem
// Siap untuk compile di FPGA (Artix-7/Zynq-7000)

// Utility modules
`include "layers/fixed_point_alu.v"
`include "layers/neuron_processing_unit.v"
`include "layers/relu.v"
`include "layers/tanh_lut.v"
`include "layers/leaky_relu.v"
`include "layers/pipelined_mac.v"
`include "layers/serialregisterIn.v"
`include "layers/serialregisterOut.v"

// Generator layers
`include "layers/layer1_generator_v2.v"
`include "layers/layer2_generator_v2.v"
`include "layers/layer3_generator_v2.v"

module top_entity (
	input  wire        clk,
	input  wire        rst_n,
	input  wire        start,
	input  wire [15:0] data_in,
	output wire [15:0] data_out,
	output wire        valid,
	output wire        busy
);
	// Serial input register (64x16bit)
	wire [5:0] in_rd_addr;
	wire [15:0] in_dout;
	wire in_done;
	reg in_en;
	reg [15:0] in_din;
	serialregisterIn #(.DATA_WIDTH(16), .DEPTH(64)) regin (
		.clk(clk), .rst(rst_n), .en(in_en), .din(in_din), .done(in_done), .rd_addr(in_rd_addr), .dout(in_dout)
	);

	// Layer 1 generator
	reg l1_start;
	wire l1_done;
	wire signed [16*256-1:0] l1_flat_output;
	layer1_generator_v2 l1gen (
		.clk(clk), .rst(rst_n), .start(l1_start),
		.flat_input({regin.mem[0],regin.mem[1],regin.mem[2],regin.mem[3],regin.mem[4],regin.mem[5],regin.mem[6],regin.mem[7],regin.mem[8],regin.mem[9],regin.mem[10],regin.mem[11],regin.mem[12],regin.mem[13],regin.mem[14],regin.mem[15],regin.mem[16],regin.mem[17],regin.mem[18],regin.mem[19],regin.mem[20],regin.mem[21],regin.mem[22],regin.mem[23],regin.mem[24],regin.mem[25],regin.mem[26],regin.mem[27],regin.mem[28],regin.mem[29],regin.mem[30],regin.mem[31],regin.mem[32],regin.mem[33],regin.mem[34],regin.mem[35],regin.mem[36],regin.mem[37],regin.mem[38],regin.mem[39],regin.mem[40],regin.mem[41],regin.mem[42],regin.mem[43],regin.mem[44],regin.mem[45],regin.mem[46],regin.mem[47],regin.mem[48],regin.mem[49],regin.mem[50],regin.mem[51],regin.mem[52],regin.mem[53],regin.mem[54],regin.mem[55],regin.mem[56],regin.mem[57],regin.mem[58],regin.mem[59],regin.mem[60],regin.mem[61],regin.mem[62],regin.mem[63]}),
		.flat_output(l1_flat_output), .done(l1_done)
	);

	// Layer 2 generator
	reg l2_start;
	wire l2_done;
	wire signed [16*256-1:0] l2_flat_output;
	layer2_generator_v2 l2gen (
		.clk(clk), .rst(rst_n), .start(l2_start),
		.flat_input(l1_flat_output), .flat_output(l2_flat_output), .done(l2_done)
	);

	// Layer 3 generator
	reg l3_start;
	wire l3_done;
	wire signed [16*784-1:0] l3_flat_output;
	layer3_generator_v2 l3gen (
		.clk(clk), .rst(rst_n), .start(l3_start),
		.flat_input(l2_flat_output), .flat_output(l3_flat_output), .done(l3_done)
	);

	// Serial output register (784x16bit)
	reg out_en, out_wr_en;
	reg [9:0] out_wr_addr;
	reg [15:0] out_din;
	wire [15:0] out_dout;
	wire out_done;
	serialregisterOut #(.DATA_WIDTH(16), .DEPTH(784)) regout (
		.clk(clk), .rst(rst_n), .en(out_en), .wr_en(out_wr_en), .wr_addr(out_wr_addr), .din(out_din), .dout(out_dout), .done(out_done)
	);

	// FSM control (sederhana, bisa dioptimasi lebih lanjut)
	// ...FSM logic, valid, busy, data_out assignment, dan pipeline control di sini...

	// Output assignment (placeholder)
	assign data_out = out_dout;
	assign valid = out_en;
	assign busy = ~out_done;

endmodule
