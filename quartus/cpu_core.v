/*
8-bit CPU core

The CPU uses a finite state machine (FSM) to fetch, decode,
execute, and complete instructions from the instruction ROM.

FSM states:
FETCH     - Read the next instruction from ROM
DECODE    - Identify the opcode, registers, and immediate
EXECUTE   - Perform the requested operation
WRITEBACK - Store results and update the program counter
HALT      - Stop instruction execution

Instruction format:
[15:12] Opcode
[11:10] Rd (destination register)
[9:8]   Rs (source register)
[7:0]   Immediate value

Opcodes:
0001 - LDI
0010 - ADD
0011 - SUB
0100 - AND
0101 - OR
0110 - JNZ
0111 - OUT
1000 - HALT

Program selection:
0 - Arithmetic and logic program (address 0)
1 - Countdown program (address 16)
*/

module cpu_core(

input clk,
input reset,
input step,
input auto_mode,
input program_select,
output reg [4:0] pc_out,
output reg [7:0] output_value,
output reg zero_flag,
output halted,
output reg [15:0] last_instruction

);

reg [2:0] state;

reg [3:0] opcode;
reg [1:0] rd;
reg [1:0] rs;
reg [7:0] immediate;

wire [7:0] read_data1;
wire [7:0] read_data2;
reg [7:0] write_data;
wire write_enable;

wire [15:0] rom_instruction;
reg [15:0] instruction_reg;


reg [1:0] alu_op;
wire [7:0] alu_result;
wire alu_zero;


localparam FETCH = 3'd0;
localparam DECODE = 3'd1;
localparam EXECUTE = 3'd2;
localparam WRITEBACK = 3'd3;
localparam HALT = 3'd4;

// Instruction ROM connection
instruction_rom rom_inst (
    .addr(pc_out),
    .instruction(rom_instruction)
);

// Register file connection
register_file reg_inst (
    .clk(clk),
    .reset(reset),
    .read_addr1(rd),
    .read_addr2(rs),
    .write_addr(rd),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

// ALU connection
alu alu_inst (
    .a(read_data1),
    .b(read_data2),
    .op(alu_op),
    .zflag(alu_zero),
    .result(alu_result)
);

assign write_enable = (state == WRITEBACK && opcode >= 4'd1 && opcode <= 4'd5);
assign halted = (state == HALT);

// ALU operation selection
always @(*) begin
    case (opcode)
	 
		4'b0010: alu_op = 2'b00; // ADD
		4'b0011: alu_op = 2'b01; // SUB
		4'b0100: alu_op = 2'b10; // AND
		4'b0101: alu_op = 2'b11; // OR
		
		
		
		
		
		
		default: alu_op = 2'b00;
	 
	 
	 
	 endcase
	 
	 
end


	always @(posedge clk) begin
		if(reset == 1) begin
		
			if( program_select == 0 ) begin
				pc_out <= 5'd0;
			end 
			
			else begin
				pc_out <= 5'd16;
			end
			
			state <= FETCH;
			output_value <= 8'd0;
			last_instruction <= 16'd0;
			instruction_reg <= 16'd0;
			zero_flag <= 1'b0;
			opcode <= 4'd0;
			rd <= 2'd0;
			rs <= 2'd0;
			immediate <= 8'd0;	
			write_data <= 8'd0;
			
		
		end 
		
		else begin
			case (state)
				
				FETCH: begin
				
					if ( step == 1 || auto_mode == 1) begin
						
						instruction_reg <=  rom_instruction;
						state <= DECODE;
					
					end
				
				end
				
				DECODE: begin
				
					opcode <= instruction_reg[15:12];
					rd <= instruction_reg[11:10];
					rs <= instruction_reg[9:8];
					immediate <= instruction_reg[7:0];
					
					state <= EXECUTE;
				
				end
				
				EXECUTE: begin
				
					case(opcode)
					
						4'b0001: begin
							//LDI
							write_data <= immediate;
						end
						
						4'b0010, 4'b0011, 4'b0100, 4'b0101: begin
							write_data <= alu_result;
							zero_flag <= alu_zero;
						end
		
					endcase
					
				state <= WRITEBACK;
				
				
				end
				
				WRITEBACK: begin
				
				last_instruction <= instruction_reg;
				
				
				// Default behavior 
				pc_out <= pc_out + 5'd1;
				state <= FETCH;
				
				case(opcode)
					4'b0110: begin
						// JNZ
						
						if(read_data1 != 0) begin 
							pc_out <= immediate[4:0];
						end
						
					end
					
					4'b0111: begin
						// OUT
						
						output_value <= read_data1;
						
					end
					
					4'b1000: begin
						// HALT
						state <= HALT;
						pc_out <= pc_out;
					end
					
					default: ;
				
				endcase
				end
				
				HALT: begin 
				
					state <= HALT;
				
				end
			
			endcase
		end
	end


endmodule