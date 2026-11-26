
`timescale 1ns/1ps

module register_file_tb();

reg clk;
reg reset;
wire [7:0] read_data1;
wire [7:0] read_data2;

reg [1:0] write_addr;
reg [7:0] write_data;
reg write_enable;

reg [1:0] read_addr1;
reg [1:0] read_addr2;

register_file dut (
    .clk(clk),
    .reset(reset),
    .read_data1(read_data1),
    .read_data2(read_data2),
    .write_addr(write_addr),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_addr1(read_addr1),
    .read_addr2(read_addr2)
);

// Clock: 10 ns period
always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    write_enable = 0;
    write_addr = 0;
    write_data = 0;
    read_addr1 = 0;
    read_addr2 = 1;

    // Test 1: Reset all registers
    #10;
    #1;
    if (read_data1 !== 8'd0 || read_data2 !== 8'd0)
        $display("FAIL: Reset");
    else
        $display("PASS: Reset");

    reset = 0;

    // Test 2: Write 5 to R0
    write_enable = 1;
    write_addr = 0;
    write_data = 8'd5;

    #10;
    #1;
    read_addr1 = 0;
    #1;
    if (read_data1 !== 8'd5)
        $display("FAIL: Write R0");
    else
        $display("PASS: Write R0");

    // Test 3: Write 3 to R1
    write_addr = 1;
    write_data = 8'd3;

    #10;
    #1;
    read_addr1 = 0;
    read_addr2 = 1;
    #1;
    if (read_data1 !== 8'd5 || read_data2 !== 8'd3)
        $display("FAIL: Two simultaneous reads");
    else
        $display("PASS: Two simultaneous reads");

    // Test 4: Disable writing
    write_enable = 0;
    write_addr = 0;
    write_data = 8'd99;

    #10;
    #1;
    if (read_data1 !== 8'd5)
        $display("FAIL: Write disable");
    else
        $display("PASS: Write disable");

    // Test 5: Reset again
    reset = 1;
    #10;
    #1;
    if (read_data1 !== 8'd0 || read_data2 !== 8'd0)
        $display("FAIL: Reset after writing");
    else
        $display("PASS: Reset after writing");

    $stop;
end

endmodule
