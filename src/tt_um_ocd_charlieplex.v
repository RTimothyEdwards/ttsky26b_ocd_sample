/*
 * Copyright (c) 2026 R. Timothy Edwards Open Circuit Design LLC
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/* Tiny Tapeout wrapper around the Charlieplex array driver	*/
/* (module charlieplex_controller.v)				*/
/* All it does is to map I/O to the canonical Tiny Tapeout I/O. */

module tt_um_ocd_charlieplex (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock (assume 50MHz maximum)
    input  wire       rst_n     // reset_n - low to reset
);

    /* Instantiate the controller */

    charlieplex_controller controller (
	.clk(clk),
	.rst_n(rst_n),
	.ser_rx(ui_in[0]),
	.led_out(uio_out),	// 8 bits output
	.led_oe(uio_oe)		// 8 bits output enable
    );

    // Currently the UART is read-only and does not generate an output.
    // All output signals should be driven to some value whether or not they are
    // used by the wrapper.

    assign uo_out = 0;

endmodule
