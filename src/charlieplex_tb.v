// Testbench for charlieplex controller using iverilog

`timescale 1 ns / 1 ps

`include "charlieplex_controller.v"

module charlieplex_tb;

reg	clk;
reg	rst_n;
reg	uart_rx;

wire [7:0] led_out;
wire [7:0] led_oe;

initial begin
	clk <= 0;
	rst_n <= 0;
	uart_rx <= 0;

	#200;

	rst_n <= 1;
end

initial begin
	$dumpfile("charlieplex_tb.vcd");
	$dumpvars(0, charlieplex_tb);

	repeat (25) begin
		repeat (1000) @(posedge clk);
		$display("+1000 cycles");
	end
	$finish;
end

always #20 clk <= (clk === 1'b0);

// Instantiate the charlieplex array
charlieplex_controller controller (
	.clk(clk),
	.rst_n(rst_n),
	.uart_rx(uart_rx),
	.led_out(led_out),
	.led_oe(led_oe)
);

endmodule;

