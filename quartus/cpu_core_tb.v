
`timescale 1ns/1ps

module cpu_core_tb();

reg clk;
reg reset;
reg step;
reg auto_mode;
reg program_select;

wire [4:0] pc_out;
wire [7:0] output_value;
wire zero_flag;
wire halted;
wire [15:0] last_instruction;

integer errors;
integer expected_count;
reg [15:0] previous_instruction;

cpu_core dut (
    .clk(clk),
    .reset(reset),
    .step(step),
    .auto_mode(auto_mode),
    .program_select(program_select),
    .pc_out(pc_out),
    .output_value(output_value),
    .zero_flag(zero_flag),
    .halted(halted),
    .last_instruction(last_instruction)
);

// Generate a clock with a 10 ns period
always #5 clk = ~clk;

// Reset CPU and select program
task reset_cpu;
    input selected_program;
    begin
        @(negedge clk);
        reset = 1;
        step = 0;
        auto_mode = 0;
        program_select = selected_program;

        @(negedge clk);
        reset = 0;
    end
endtask

// Execute one instruction and verify its result
task check_step;
    input [3:0] expected_opcode;
    input [4:0] expected_pc;
    input [7:0] expected_output;
    input expected_zero;
    input expected_halted;

    begin
        @(negedge clk);
        step = 1;

        @(negedge clk);
        step = 0;

        // Wait for DECODE, EXECUTE and WRITEBACK
        repeat (3) @(negedge clk);

        if (pc_out !== expected_pc ||
            output_value !== expected_output ||
            zero_flag !== expected_zero ||
            halted !== expected_halted ||
            last_instruction[15:12] !== expected_opcode) begin

            errors = errors + 1;

            $display("FAIL: opcode=%h PC=%d OUT=%d Z=%b HALT=%b",
                     last_instruction[15:12], pc_out,
                     output_value, zero_flag, halted);
        end
        else begin
            $display("PASS: opcode=%h PC=%d OUT=%d Z=%b HALT=%b",
                     last_instruction[15:12], pc_out,
                     output_value, zero_flag, halted);
        end
    end
endtask

initial begin
    clk = 0;
    reset = 1;
    step = 0;
    auto_mode = 0;
    program_select = 0;
    errors = 0;

    /*
    Program 1: Arithmetic and logic
    Manual instruction stepping
    */

    $display("Testing Program 1");

    reset_cpu(0);

    // Opcode, expected PC, output, zero flag, halted
    check_step(4'h1, 5'd1, 8'd0, 0, 0); // LDI R0, 5
    check_step(4'h1, 5'd2, 8'd0, 0, 0); // LDI R1, 3
    check_step(4'h2, 5'd3, 8'd0, 0, 0); // ADD
    check_step(4'h7, 5'd4, 8'd8, 0, 0); // OUT
    check_step(4'h4, 5'd5, 8'd8, 1, 0); // AND
    check_step(4'h7, 5'd6, 8'd0, 1, 0); // OUT
    check_step(4'h5, 5'd7, 8'd0, 0, 0); // OR
    check_step(4'h7, 5'd8, 8'd3, 0, 0); // OUT
    check_step(4'h8, 5'd8, 8'd3, 0, 1); // HALT

    // Verify that the CPU remains halted
    auto_mode = 1;
    repeat (8) @(negedge clk);

    if (halted !== 1'b1 || pc_out !== 5'd8 ||
        output_value !== 8'd3) begin
        $display("FAIL: CPU did not remain halted");
        errors = errors + 1;
    end

    /*
    Program 2: Countdown
    Automatic instruction execution
    */

    $display("Testing Program 2");

    reset_cpu(1);

    expected_count = 9;
    previous_instruction = 16'd0;
    auto_mode = 1;

    repeat (160) begin
        @(negedge clk);

        // Check each completed OUT instruction
        if (last_instruction[15:12] == 4'h7 &&
            last_instruction != previous_instruction) begin

            if (output_value !== expected_count[7:0]) begin
                $display("FAIL: Expected %d, got %d",
                         expected_count, output_value);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Countdown output = %d",
                         output_value);
            end

            expected_count = expected_count - 1;
        end

        previous_instruction = last_instruction;
    end

    if (halted !== 1'b1 || output_value !== 8'd0 ||
        pc_out !== 5'd22 || expected_count != -1 ||
        zero_flag !== 1'b1) begin

        $display("FAIL: Countdown final state");
        errors = errors + 1;
    end
    else begin
        $display("PASS: Countdown completed");
    end

    if (errors == 0)
        $display("ALL CPU TESTS PASSED");
    else
        $display("CPU TESTS FAILED: %d errors", errors);

    $stop;
end

endmodule
