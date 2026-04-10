module i2c_slave_driver(
    input clk,
    input rst,
    
    // Interface to core
    inout sda,
    input scl,
    output sda_ctrl,
    
    // Interface to registers
    input [2:0] reg_addr,
    input wr_en,
    input rd_en,
    input [7:0] wdata,
    output [7:0] rdata,
    output done
);

wire [7:0] data_in;
wire [6:0] slave_addr;
wire busy, done, data_ready;

i2c_slave_regs i2c_slave_regs_inst(.clk(clk), .rst(rst), .data_in(data_in), .slave_addr_out(slave_addr),
    .busy(busy), .wr_en(wr_en), .rd_en(rd_en), .reg_addr(reg_addr), .wdata(wdata), .rdata(rdata));


i2c_slave i2c_slave_inst(.clk(clk), .rst(rst), .sda(sda), .scl(scl), .slave_addr(slave_addr), .busy(busy),
    .data_out(data_out), .data_ready(data_ready), .sda_ctrl(sda_ctrl), .done(done));

endmodule
