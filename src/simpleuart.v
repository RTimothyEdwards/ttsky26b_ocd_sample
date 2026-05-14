/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

/* Source modified to remove the UART transmitter and keep the UART receiver
 * only.  Divider reduced from 32 to 16 bits, which is sufficient to get from
 * 50MHz clock down to 9600 baud, and then set to a fixed value for 9600
 * baud operation.  Data values limited to 8 bits.
 */

module simpleuart #(parameter integer DEFAULT_DIV = 1041) (
	input  wire 	  clk,
	input  wire 	  resetn,
	input  wire 	  ser_rx,
	input  wire       reg_dat_re,
	output wire [7:0] reg_dat_do,
	output reg    	  recv_buf_valid
);
	reg [3:0] recv_state;
	reg [10:0] recv_divcnt;
	reg [7:0] recv_pattern;
	reg [7:0] recv_buf_data;

	assign reg_dat_do = recv_buf_valid ? recv_buf_data : ~0;

	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			recv_state <= 0;
			recv_divcnt <= 0;
			recv_pattern <= 0;
			recv_buf_data <= 0;
			recv_buf_valid <= 0;
		end else begin
			recv_divcnt <= recv_divcnt + 1;
			if (reg_dat_re)
				recv_buf_valid <= 0;
			case (recv_state)
				0: begin
					if (!ser_rx)
						recv_state <= 1;
					recv_divcnt <= 0;
				end
				1: begin
					if (2*recv_divcnt > DEFAULT_DIV) begin
						recv_state <= 2;
						recv_divcnt <= 0;
					end
				end
				10: begin
					if (recv_divcnt > DEFAULT_DIV) begin
						recv_buf_data <= recv_pattern;
						recv_buf_valid <= 1;
						recv_state <= 0;
					end
				end
				default: begin
					if (recv_divcnt > DEFAULT_DIV) begin
						recv_pattern <= {ser_rx, recv_pattern[7:1]};
						recv_state <= recv_state + 1;
						recv_divcnt <= 0;
					end
				end
			endcase
		end
	end

endmodule
