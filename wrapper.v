`default_nettype none
`ifdef FORMAL
    `define MPRJ_IO_PADS 38    
`endif

`define USE_WB  1
//`define USE_LA  0
`define USE_IO  1
//`define USE_MEM 0
//`define USE_IRQ 0

// update this to the name of your module
module wrapped_wiggly_ic_1 (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    input wire wb_clk_i,            // clock, runs at system clock
 // wishbone interface
`ifdef USE_WB
    input wire wb_rst_i,            // main system reset
    input wire wbs_stb_i,           // wishbone write strobe
    input wire wbs_cyc_i,           // wishbone cycle
    input wire wbs_we_i,            // wishbone write enable
    input wire [3:0] wbs_sel_i,     // wishbone write word select
    input wire [31:0] wbs_dat_i,    // wishbone data in
    input wire [31:0] wbs_adr_i,    // wishbone address
    output wire wbs_ack_o,          // wishbone ack
    output wire [31:0] wbs_dat_o,   // wishbone data out
`endif
    // Logic Analyzer Signals
    // only provide first 32 bits to reduce wiring congestion
`ifdef USE_LA
    input  wire [31:0] la1_data_in,  // from PicoRV32 to your project
    output wire [31:0] la1_data_out, // from your project to PicoRV32
    input  wire [31:0] la1_oenb,     // output enable bar (low for active)
`endif

    // IOs
`ifdef USE_IO
    input  wire [`MPRJ_IO_PADS-1:0] io_in,  // in to your project
    output wire [`MPRJ_IO_PADS-1:0] io_out, // out fro your project
    output wire [`MPRJ_IO_PADS-1:0] io_oeb, // out enable bar (low active)
`endif

    // IRQ
`ifdef USE_IRQ
    output wire [2:0] user_irq,          // interrupt from project to PicoRV32
`endif

`ifdef USE_CLK2
    // extra user clock
    input wire user_clock2,
`endif
    
    // active input, only connect tristated outputs if this is high
    input wire active
);

    // all outputs must be tristated before being passed onto the project
    wire buf_wbs_ack_o;
    wire [31:0] buf_wbs_dat_o;
    wire [31:0] buf_la1_data_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_out;
    wire [`MPRJ_IO_PADS-1:0] buf_io_oeb;
    wire [2:0] buf_user_irq;

    `ifdef FORMAL
    // formal can't deal with z, so set all outputs to 0 if not active
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'b0;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'b0;
    `endif
    `ifdef USE_LA
    assign la1_data_out = active ? buf_la1_data_out  : 32'b0;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'b0}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'b0}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'b0;
    `endif
    `include "properties.v"
    `else
    // tristate buffers
    
    `ifdef USE_WB
    assign wbs_ack_o    = active ? buf_wbs_ack_o    : 1'bz;
    assign wbs_dat_o    = active ? buf_wbs_dat_o    : 32'bz;
    `endif
    `ifdef USE_LA
    assign la1_data_out  = active ? buf_la1_data_out  : 32'bz;
    `endif
    `ifdef USE_IO
    assign io_out       = active ? buf_io_out       : {`MPRJ_IO_PADS{1'bz}};
    assign io_oeb       = active ? buf_io_oeb       : {`MPRJ_IO_PADS{1'bz}};
    `endif
    `ifdef USE_IRQ
    assign user_irq     = active ? buf_user_irq          : 3'bz;
    `endif
    `endif

    // permanently set oeb so that outputs are always enabled: 0 is output, 1 is high-impedance
    assign buf_io_oeb[9:0] = '0;
    assign buf_io_oeb[10] = !mouse_clk_oe;
    assign buf_io_oeb[11] = !mouse_data_oe;
    assign buf_io_oeb[`MPRJ_IO_PADS-1:12] = '0;

    // Instantiate your module here, 
    // connecting what you need of the above signals. 
    // Use the buffered outputs for your module's outputs.

    wire       mouse_clk_oe, mouse_data_oe;
    wiggly_ic_1 wiggly_ic_1_inst (
      .clk(wb_clk_i), .rst(wb_rst_i),

      .kbd_clk(io_in[8]),
      .kbd_data(io_in[9]),

      .mouse_clk_in(io_in[10]),
      .mouse_data_in(io_in[11]),
      .mouse_clk_out(buf_io_out[10]),
      .mouse_data_out(buf_io_out[11]),
      .mouse_clk_oe,
      .mouse_data_oe,

      .vga_clk_pix(wb_clk_i),
      .vga_r(buf_io_out[13:12]),
      .vga_g(buf_io_out[15:14]),
      .vga_b(buf_io_out[17:16]),
      .vga_hsync(buf_io_out[18]),
      .vga_vsync(buf_io_out[19])
    );
    
endmodule 
`default_nettype wire
