
/*
8-bit CPU instruction set

Instruction format:
[15:12] Opcode
[11:10] Rd (destination register)
[9:8]   Rs (source register)
[7:0]   Immediate value

Opcodes:
0001 - LDI   Load immediate into Rd
0010 - ADD   Rd = Rd + Rs
0011 - SUB   Rd = Rd - Rs
0100 - AND   Rd = Rd & Rs
0101 - OR    Rd = Rd | Rs
0110 - JNZ   Jump to immediate[4:0] if Rd != 0
0111 - OUT   Output the value of Rd
1000 - HALT  Stop execution
*/

module instruction_rom(
    input [4:0] addr,
    output reg [15:0] instruction
);

reg [15:0] rom [31:0];
integer i;

initial begin

    // Initialize all 32 ROM locations to HALT
    for (i = 0; i < 32; i = i + 1)
        rom[i] = 16'b1000_00_00_00000000;

    /*
    Program 1: Arithmetic and logic
    Addresses 0-15
    */

    rom[0] = 16'b0001_00_00_00000101; // LDI R0, 5
    rom[1] = 16'b0001_01_00_00000011; // LDI R1, 3
    rom[2] = 16'b0010_00_01_00000000; // ADD R0, R1 -> R0 = 8
    rom[3] = 16'b0111_00_00_00000000; // OUT R0 -> Output = 8
    rom[4] = 16'b0100_00_01_00000000; // AND R0, R1 -> R0 = 0
    rom[5] = 16'b0111_00_00_00000000; // OUT R0 -> Output = 0
    rom[6] = 16'b0101_00_01_00000000; // OR R0, R1 -> R0 = 3
    rom[7] = 16'b0111_00_00_00000000; // OUT R0 -> Output = 3
    rom[8] = 16'b1000_00_00_00000000; // HALT

    /*
    Program 2: Countdown
    Addresses 16-31
    */

    rom[16] = 16'b0001_00_00_00001001; // LDI R0, 9
    rom[17] = 16'b0001_01_00_00000001; // LDI R1, 1

    // Countdown loop begins at address 18
    rom[18] = 16'b0111_00_00_00000000; // OUT R0
    rom[19] = 16'b0011_00_01_00000000; // SUB R0, R1
    rom[20] = 16'b0110_00_00_00010010; // JNZ R0, 18

    rom[21] = 16'b0111_00_00_00000000; // OUT R0
    rom[22] = 16'b1000_00_00_00000000; // HALT

end

// Combinational instruction read
always @(*) begin
    instruction = rom[addr];
end

endmodule
