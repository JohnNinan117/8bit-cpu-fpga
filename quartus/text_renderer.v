module text_renderer(

input [31:0] column,
input [31:0] row,
input [6:0] char_code,
output pixel_on

);

wire [3:0] font_row;
wire [2:0] font_column;
wire [7:0] font_pixels;


assign font_row = row[4:1];
assign font_column = column[3:1];



// Retrieve the bitmap row for the selected character
font_rom font_inst (
    .char_code(char_code),
    .row(font_row),
    .pixels(font_pixels)
);

// Determine whether the current pixel belongs to the character
assign pixel_on = font_pixels[7 - font_column];


endmodule