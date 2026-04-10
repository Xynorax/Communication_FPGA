module i2c_slave_regs(
    input clk,
    input rst,

    // Interface to I2C slave core
    input [7:0] data_in, 
    output reg [6:0] slave_addr_out,   
    input busy,
    // Interface to Device  
    input wr_en,              
    input rd_en,  
    input [2:0] reg_addr,
    input [7:0] wdata,
    output reg [7:0] rdata
);

reg [7:0] registers [0:4];
integer i;

always@(posedge clk, posedge rst) begin
    if(rst) begin
        for (i=0; i<5; i=i+1) begin
            registers[i] <= 8'h00;
        end
    end else begin
    
        // Update status registers
        registers[1][0] <= busy;
        
        if(wr_en) begin
            registers[reg_addr] <= wdata;
        end
        if(rd_en) begin
            rdata <= registers[reg_addr];
        end
    end
end
    
always @(*) begin
    slave_addr_out <= registers[2][6:0];
end
endmodule