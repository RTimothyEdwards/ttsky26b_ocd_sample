// Testbench for charlieplex controller (FPGA version)

`timescale 1 ns / 1 ps

`include "charlieplex_controller.v"
`include "tt_um_ocd_charlieplex.v"
`include "simpleuart.v"
`include "../fpga/tt_ocd_charlieplex_wrapper.v"

module charlieplex_top_tb;

reg	clk;
reg	rst_n;
reg	ser_rx_in;
reg [7:0] ui_in;

wire [7:0] uio_inout;
wire [7:0] uo_out;
wire	   ser_tx_out;	// Always zero

initial begin
	$dumpfile("charlieplex_top_tb.vcd");
	$dumpvars(0, charlieplex_top_tb);

	clk <= 0;
	rst_n <= 0;
	ser_rx_in <= 1'b1;
	ui_in <= 0;

	#200;

	rst_n <= 1;

	#20000;

	// Send UART 'H' (0x48) at 9600 baud (LED index = 1)
	// 9600 baud = 104167ns per bit

	ser_rx_in <= 1'b0;	// Start bit
	#104167;
	ser_rx_in <= 1'b0;	// Write from lowest bit
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b1;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b1;
	#104167;
	ser_rx_in <= 1'b0;	// Stop bit
	#104167;
	ser_rx_in <= 1'b1;	// Idle state
	#104167;

	// Send UART '0' (0x30) at 9600 baud

	ser_rx_in <= 1'b0;	// Start bit
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b1;
	#104167;
	ser_rx_in <= 1'b1;
	#104167;
	ser_rx_in <= 1'b0;
	#104167;
	ser_rx_in <= 1'b0;	// Stop bit
	#104167;
	ser_rx_in <= 1'b1;	// Idle state

	#500000;

	$finish;
end

always #10 clk <= (clk === 1'b0);

// Instantiate the charlieplex top level
tt_ocd_charlieplex_wrapper wrapper (
	.clk(clk),
	.rst_n(rst_n),
	.ser_rx_in(ser_rx_in),
	.ser_tx_out(ser_tx_out),
	.ui_in(ui_in),
	.uo_out(uo_out),
	.uio_inout(uio_inout)
);

endmodule;

