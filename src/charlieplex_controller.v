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

    // Every charlieplex array by definition has N*(N-1) LEDs, where N
    // is the number of pins driving the array.  Assume that N is a
    // power of 2, so that the count over N is simply the lower bits
    // of the count over N*(N-1).

    localparam NUM_PINS = 8;
    localparam GREYSCALE_BITS = 3;

    localparam NUM_LEDS = NUM_PINS * (NUM_PINS - 1);
    
    // frame buffer: 56 LEDs x 3 bits = 168 bits
    reg [GREYSCALE_BITS-1:0] brightness [0:NUM_LEDS-1];
    
    // UART receiver for loading brightness values
    reg [5:0]	uart_led_cnt;
    
    wire [7:0]  uart_do;
    wire	uart_valid;
    reg		uart_re;

    integer i, x, y;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_led_cnt <= 0;
	    uart_re <= 0;

	    // Test: set all LEDs to be on by default, with a brightness gradient
	    for (i = 0; i < NUM_LEDS; i = i + 1) begin
	        brightness[i] <= (i <  8) ? 7 :
				 (i < 16) ? 6 :
				 (i < 24) ? 5 :
				 (i < 32) ? 4 :
				 (i < 40) ? 3 :
				 (i < 48) ? 2 :
				 	    1 ;
	    end
        end else begin
	    if (uart_valid && !uart_re) begin
		// UART assume ascii codes
		// Valid codes:  '0'-'7' is a brightness value.
		// 'G' + 0-55 = reset LED index to this value (0 to 55)
		if (uart_do < 58) begin
	 	    brightness[uart_led_cnt] <= (uart_do - 48);
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
    reg [5:0] led_index;       		// LED position being addressed
    reg [GREYSCALE_BITS-1:0] on_cnt;    // counter for time LED is on
    reg [5:0] base_cnt;			// minimum clocks per LED cycle

    // Break index down into X and Y fields
    wire [2:0] led_x = led_index[2:0];
    wire [2:0] led_y = led_index[5:3];

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
            if (on_cnt == 3'b111 && base_cnt == 6'b111111) begin
		led_on <= 1'b0;
		base_cnt <= 0;
		on_cnt <= 0;
                // done with this LED
                if (led_index == NUM_LEDS - 1) begin
                    // done with all LEDs, return to beginning
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
    
    wire [2:0] anode_pin;
    wire [2:0] cathode_pin;

    // Map the pin positions of the LED cathode and anode to the index.
    // The cathode simply counts down from 7 to 0 (~led_x), while the anode
    // counts up from 0 to 6 but in groups of 7.  Possibly this could be
    // done more efficiently with one count-by-8 counter and one count-by-7
    // counter.
    //
    // Index:   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 ...
    // Anode:   0  0  0  0  0  0  0  1  1  1  1  1  1  1  2  2  2  2  2 ...
    // Cathode: 7  6  5  4  3  2  1  0  7  6  5  4  3  2  1  0  7  6  5 ...
    
    assign cathode_pin = ~led_x;
    assign anode_pin = (cathode_pin > led_y) ? led_y : led_y + 1;

    // Output generation

    always @(*) begin
	// Default:  pin stays Hi-Z (oe=0)
	led_oe = 8'b0;
	led_out = 8'b0;

	if (led_on) begin
	    // The anode pin gets set to one
	    led_oe[anode_pin] = 1'b1;
	    led_out[anode_pin] = 1'b1;

	    // The cathode pin gets set to zero
	    led_oe[cathode_pin] = 1'b1;
	    led_out[cathode_pin] = 1'b0;
	end
    end

endmodule
