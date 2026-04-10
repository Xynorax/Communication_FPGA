`timescale 1ns / 1ps
module i2c_master_regs(
    input clk,
    input rst,

    input wr_en,
    input rd_en,
    input [2:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,

    // connections to I2C core
    output reg start,
    output reg rw,
    output reg [6:0] slave_addr,
    output reg [7:0] data_tx,
    input [7:0] data_rx,
    input busy,
    input done
);
reg [7:0] registers[0:4];
// ctrl;
// status;
// addr_reg;
// data_tx_reg;
// data_rx_reg;
integer i;
always@(posedge clk, posedge rst) begin
    if(rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            registers[i] <= 8'h00;
        end
    end else begin
        if(wr_en)
            registers[addr] <= wdata;
        else if (start)
            registers[0][0] <= 0;
            
        if(rd_en)
            rdata <= registers[addr];
    end
end
always @(*) begin
    start <= registers[0][0];
    rw    <= registers[0][1];
    slave_addr <= registers[2][6:0];
    data_tx <= registers[3];
end
endmodule
