/*
 * tt_ww_charlieplex_wrapper.v
 *
 * Wrapper for Arty A7 board around the
 * TinyTapeout project tt_ww_charlieplex.v
 *
 * What this wrapper adds:
 *
 * (1) Divide-by-2 on the clock to match the TinyTapeout
 *     development board running at 50MHz
 * (2) Bidirectional pin handling
 * (3) UART-to-SPI to use the Arty's FTDI for USB communication
 *
 */

// Note that this creates new signal name "uio_inout" which is
// what must be connected to the eight pins in the "JB" PMOD
// in the Arty board configuration file.
//
// Two more signals are added:  ser_tx_out and ser_rx_in.  These
// need to be connected to the FTDI in the Arty board configuration
// file.

module tt_ocd_charlieplex_wrapper (
    inout  wire [7:0] uio_inout,  // Bidirectional input and output (JB PMOD)
    input  wire [7:0] ui_in,	  // (Unused) input (JA PMOD)
    output wire [7:0] uo_out,	  // (Unused) output (JC PMOD)
    input  wire       clk,        // clock
    input  wire       rst_n,      // reset - low to reset
    input  wire	      ser_rx_in,  // UART input from FTDI on Arty board
    output wire	      ser_tx_out  // UART output to FTDI on Arty board
);

    reg clk2;

    // To mimic the Tiny Tapeout configuration, the module
    // tt_um_ocd_charlieplex is kept, which is the top level Tiny Tapeout
    // module with the assigned Tiny Tapeout I/O.
    // The UART input is switched from the ui_in PMOD port A on the Tiny
    // Tapeout board to the FTDI UART output.
    //
    // ui_in[0]  = ser_rx_in

    wire [7:0] uio_oe;
    wire [7:0] uio_in;
    wire [7:0] uio_out;

    assign ser_tx_out = 1'b0;	// No UART output

    // Instantiate the Tiny Tapeout project

    tt_um_ocd_charlieplex project (
	.ui_in({ui_in[7:1], ser_rx_in}),	// 8-bit input
	.uo_out(uo_out),	// 8-bit output (not used)
	.uio_in(uio_in),	// 8-bit bidirectional (in)
	.uio_out(uio_out),	// 8-bit bidirectional (out)
	.uio_oe(uio_oe),	// 8-bit bidirectional (enable)
	.ena(1'b1),		// project enable (not used)
	.clk(clk2),		// halved clock
	.rst_n(rst_n)		// inverted reset
    );

    // Handle bidirectional I/Os
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1)
            assign uio_inout[i] = uio_oe[i] ? uio_out[i] : 1'bz;
    endgenerate
    assign uio_in = uio_inout;

    // Halve the clock

    always @(posedge clk) begin
	if (rst_n) begin
	    clk2 <= ~clk2;
	end else begin
	    clk2 <= 0;
	end
    end

endmodule;

