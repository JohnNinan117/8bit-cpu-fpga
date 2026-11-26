module register_file (
input  clk,
input reset,

input [1:0] read_addr1,
input [1:0] read_addr2,

input  [1:0] write_addr,
input  [7:0] write_data,
input write_enable,

output [7:0] read_data1,
output [7:0] read_data2

);

reg [7:0] registers [0:3];

assign read_data1 = registers[read_addr1];
assign read_data2 = registers[read_addr2];

always @(posedge clk) begin

	if(reset == 1) begin
	
	registers[0] <= 8'd0;
	registers[1] <= 8'd0;
	registers[2] <= 8'd0;
	registers[3] <= 8'd0;
	
	end

	else if(write_enable == 1) begin
		registers[write_addr] <= write_data;
	end
	
	
end


endmodule