// Charlieplex LED Controller for TinyTapeout
// 8 pins -> 56 LEDs, 4-bit grayscale using BCM
// MODIFIED BY WADOOD 12/11/2025 for initial version of controller
// Modified by Tim 5/08/2026 to replace SPI with a UART

module charlieplex_controller (
    input  wire       clk,
    input  wire       rst_n,
    
    // UART interface for loading frame buffer
    input  wire	      ser_rx,
    
    // active-high output enable and active-low output enable
    output reg  [7:0] led_out,
    output reg  [7:0] led_oe
);

    localparam NUM_PINS = 8;
    localparam NUM_LEDS = 56;
    localparam GREYSCALE_BITS = 4;
    
    // frame buffer: 56 LEDs x 4 bits = 224 bits
    reg [GREYSCALE_BITS-1:0] brightness [0:NUM_LEDS-1];
    
    // UART receiver for loading brightness values
    reg [5:0]	uart_led_cnt;
    
    wire [7:0]  uart_do;
    wire	uart_valid;
    reg		uart_re;

    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_led_cnt <= 0;
	    uart_re <= 0;

	    // Test: set all LEDs to be on by default, with a brightness gradient
	    for (i = 0; i < NUM_LEDS; i = i + 1)
	        brightness[i] <= (i < 7)  ? 15 :
				 (i < 14) ? 11 :
				 (i < 21) ?  8 :
				 (i < 28) ?  6 :
				 (i < 35) ?  4 :
				 (i < 42) ?  3 :
				 (i < 49) ?  2 :
				 1 ;

        end else begin
	    if (uart_valid && !uart_re) begin
		// UART assume ascii codes
		// Valid codes:  '0'-'9' and 'A'-'F' = 0-15 is a brightness value.
		// 'G' + 0-55 = reset LED index to this value (0 to 55)
		if (uart_do < 58) begin
	 	    brightness[uart_led_cnt] <= (uart_do - 48);
		    uart_led_cnt <= uart_led_cnt + 1;
		end else if (uart_do < 71) begin
	 	    brightness[uart_led_cnt] <= (uart_do - 55);
		    uart_led_cnt <= uart_led_cnt + 1;
		end else begin
		    uart_led_cnt <= (uart_do - 71);
		end
		uart_re <= 1'b1;
	    end else begin
		uart_re <= 1'b0;
	    end
        end
    end

    // Instantiate the UART
    simpleuart uart (
	.clk(clk),
	.resetn(rst_n),
	.ser_rx(ser_rx),
	.reg_dat_re(uart_re),
	.reg_dat_do(uart_do),
	.recv_buf_valid(uart_valid)
    );

    
    // BCM Scan Controller
    reg [5:0] led_index;        		// 0-55: LED being addressed
    reg [GREYSCALE_BITS-1:0] on_cnt;    	// counter for time LED is on
    reg [5:0] base_cnt;				// minimum clocks per LED cycle
    
    // current LED's brightness value
    wire [GREYSCALE_BITS-1:0] current_brightness = brightness[led_index];
    
    reg led_on;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
	    led_on <= 1'b0;
            led_index <= 0;
            on_cnt <= 0;
	    base_cnt <= 0;
        end else begin
            if (on_cnt == 4'b1111 && base_cnt == 6'b111111) begin
		led_on <= 1'b0;
		base_cnt <= 0;
		on_cnt <= 0;
                // done with this LED
                if (led_index == NUM_LEDS - 1) begin
                    // done with all LEDs, move to next bit plane
                    led_index <= 0;
                end else begin
                    led_index <= led_index + 1;
                end
	    end else if (base_cnt == 6'b111111) begin
		base_cnt <= 0;
		on_cnt <= on_cnt + 1;
            end else begin
		if (on_cnt >= current_brightness) begin
		    led_on <= 1'b0;
		end else begin
		    led_on <= 1'b1;
		end
                base_cnt <= base_cnt + 1;
            end
        end
    end
    
    // with 8 pins numbered 0-7:
    //   LED 0-6:   anode=0, cathode=1,2,3,4,5,6,7
    //   LED 7-13:  anode=1, cathode=0,2,3,4,5,6,7
    //   etc
    wire [2:0] anode_pin;
    wire [2:0] cathode_pin;
    wire [2:0] cathode_offset;
    
    assign anode_pin = led_index / 7;
    assign cathode_offset = led_index % 7;
    // skip over the anode pin number in the cathode sequence
    assign cathode_pin = (cathode_offset < anode_pin) ? cathode_offset : (cathode_offset + 1);
    
    // output generation
    
    always @(*) begin
        if (led_on) begin
            // drive anode HIGH, cathode LOW, others Hi-Z
            for (i = 0; i < 8; i = i + 1) begin
                if (i == anode_pin) begin
                    led_out[i] <= 1'b1;
                    led_oe[i] <= 1'b1;
                end else if (i == cathode_pin) begin
                    led_out[i] <= 1'b0;
                    led_oe[i] <= 1'b1;
                end else begin
                    // default:  pin stays Hi-Z (oe=0)
        	    led_out[i] <= 1'b0;
		    led_oe[i] <= 1'b0;
		end
            end
        end else begin
	    led_out <= 8'b0;
	    led_oe <= 8'b0;
	end
    end

endmodule
