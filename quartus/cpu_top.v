/*
CPU top-level module

KEY0 - Reset CPU
KEY1 - Execute one instruction in manual mode
SW0  - Manual/automatic execution
SW1  - Program selection

Automatic mode executes one instruction every 0.3 seconds.
*/

module cpu_top(
    input MAX10_CLK1_50,
    input [1:0] KEY,
    input [9:0] SW,
    output [9:0] LEDR,
    output [7:0] HEX0,
    output [7:0] HEX1,
    output VGA_HS,
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B
);

// CPU control signals
wire reset;
wire step;
wire auto_mode;
wire program_select;

// Automatic execution signals
reg [23:0] auto_counter;
reg auto_step;

// Manual execution and button debouncing
reg previous_KEY1;
reg key1_meta;
reg key1_sync;
reg [19:0] debounce_counter;
reg manual_step;

// CPU output signals
wire [4:0] pc_out;
wire [7:0] output_value;
wire zero_flag;
wire halted;
wire [15:0] last_instruction;

// Map physical board inputs to CPU controls
assign reset = ~KEY[0];
assign auto_mode = SW[0];
assign program_select = SW[1];

// Synchronize KEY1 to the FPGA clock
always @(posedge MAX10_CLK1_50) begin
    key1_meta <= KEY[1];
    key1_sync <= key1_meta;
end

/*
Button debouncing and falling-edge detection.
The button must remain stable for 20 ms before
its new state is accepted.
*/

always @(posedge MAX10_CLK1_50) begin

    if (reset) begin
        previous_KEY1 <= 1'b1;
        debounce_counter <= 20'd0;
        manual_step <= 1'b0;
    end

    else begin

        manual_step <= 1'b0;

        if (key1_sync != previous_KEY1) begin

            if (debounce_counter == 20'd999999) begin
                previous_KEY1 <= key1_sync;
                debounce_counter <= 20'd0;

                // Generate a pulse when KEY1 is pressed
                if (key1_sync == 0)
                    manual_step <= 1'b1;
            end

            else begin
                debounce_counter <= debounce_counter + 1'b1;
            end

        end

        else begin
            debounce_counter <= 20'd0;
        end
    end
end

/*
Automatic execution counter.
The 50 MHz clock produces 15,000,000 cycles in 0.3 seconds.
Generate one execution pulse after each interval.
*/

always @(posedge MAX10_CLK1_50) begin

    if (reset || !auto_mode) begin
        auto_counter <= 24'd0;
        auto_step <= 1'b0;
    end

    else if (auto_counter == 24'd14999999) begin
        auto_counter <= 24'd0;
        auto_step <= 1'b1;
    end

    else begin
        auto_counter <= auto_counter + 1'b1;
        auto_step <= 1'b0;
    end

end

// Select the execution pulse based on the operating mode
assign step = auto_mode ? auto_step : manual_step;

// CPU core connection
cpu_core cpu_inst (
    .clk(MAX10_CLK1_50),
    .reset(reset),
    .step(step),
    .auto_mode(1'b0),
    .program_select(program_select),
    .pc_out(pc_out),
    .output_value(output_value),
    .zero_flag(zero_flag),
    .halted(halted),
    .last_instruction(last_instruction)
);

// CPU status indicators
assign LEDR[4:0] = pc_out;
assign LEDR[5] = zero_flag;
assign LEDR[6] = halted;
assign LEDR[7] = auto_mode;
assign LEDR[8] = program_select;
assign LEDR[9] = 1'b0;

// Display the CPU output as two hexadecimal digits
assign HEX0 = seven_segment(output_value[3:0]);
assign HEX1 = seven_segment(output_value[7:4]);

/*
Seven-segment hexadecimal decoder.
The DE10-Lite displays are active-low.
Supports hexadecimal values from 0 to F.
*/

function [7:0] seven_segment;
    input [3:0] digit;

    begin
        case (digit)
            4'h0: seven_segment = 8'b11000000;
            4'h1: seven_segment = 8'b11111001;
            4'h2: seven_segment = 8'b10100100;
            4'h3: seven_segment = 8'b10110000;
            4'h4: seven_segment = 8'b10011001;
            4'h5: seven_segment = 8'b10010010;
            4'h6: seven_segment = 8'b10000010;
            4'h7: seven_segment = 8'b11111000;
            4'h8: seven_segment = 8'b10000000;
            4'h9: seven_segment = 8'b10010000;
            4'hA: seven_segment = 8'b10001000;
            4'hB: seven_segment = 8'b10000011;
            4'hC: seven_segment = 8'b11000110;
            4'hD: seven_segment = 8'b10100001;
            4'hE: seven_segment = 8'b10000110;
            4'hF: seven_segment = 8'b10001110;
            default: seven_segment = 8'b11111111;
        endcase
    end

endfunction

// VGA signals
wire pixel_clk;
wire disp_ena;
wire [31:0] column;
wire [31:0] row;

// Generate the 25.175 MHz VGA pixel clock
pll pll_inst (
    .inclk0(MAX10_CLK1_50),
    .c0(pixel_clk)
);

// Generate VGA synchronization and pixel coordinates
vga_controller vga_inst (
    .pixel_clk(pixel_clk),
    .reset_n(KEY[0]),
    .h_sync(VGA_HS),
    .v_sync(VGA_VS),
    .disp_ena(disp_ena),
    .column(column),
    .row(row)
);

// White text on a dark teal background
assign VGA_R = disp_ena ? (pixel_on ? 4'hF : 4'h0) : 4'h0;
assign VGA_G = disp_ena ? (pixel_on ? 4'hF : 4'h4) : 4'h0;
assign VGA_B = disp_ena ? (pixel_on ? 4'hF : 4'h4) : 4'h0;

// Text rendering signals
wire [5:0] char_column;
wire [3:0] char_row;
reg [6:0] char_code;
wire pixel_on;

// Convert screen coordinates into character coordinates
assign char_column = column[9:4];
assign char_row = row[8:5];

// Test message at character row 2
always @(*) begin

    char_code = " ";

    if (char_row == 4'd2) begin
        case (char_column)
            6'd2:  char_code = "H";
            6'd3:  char_code = "e";
            6'd4:  char_code = "l";
            6'd5:  char_code = "l";
            6'd6:  char_code = "o";
            6'd7:  char_code = " ";
            6'd8:  char_code = "W";
            6'd9:  char_code = "o";
            6'd10: char_code = "r";
            6'd11: char_code = "l";
            6'd12: char_code = "d";
            default: char_code = " ";
        endcase
    end

end

text_renderer text_inst (
    .column(column),
    .row(row),
    .char_code(char_code),
    .pixel_on(pixel_on)
);
endmodule