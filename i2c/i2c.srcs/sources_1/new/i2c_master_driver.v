`timescale 1ns / 1ps

module i2c_master_driver(
    input clk,
    input rst,

    // register interface
    input wr_en,
    input rd_en,
    input [2:0] addr,
    input [7:0] wdata,
    output [7:0] rdata,
    
    
    // I2C pins
    inout sda,
    output scl,
    output sda_ctrl
);

    wire start;
    wire rw;
    wire [6:0] slave_addr;
    wire [7:0] data_tx;
    wire [7:0] data_rx;
    wire busy;
    wire done;

    // -----------------------------
    // Register File
    // -----------------------------
    i2c_master_regs regs (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),

        .start(start),
        .rw(rw),
        .slave_addr(slave_addr),
        .data_tx(data_tx),
        .data_rx(data_rx),
        .busy(busy),
        .done(done)
    );

    // -----------------------------
    // I2C Master FSM
    // -----------------------------
    i2c_master core (
        .clk(clk),
        .rst(rst),
        .start(start),
        .address(slave_addr),
        .rw(rw),
        .data_in(data_tx),

        .data_out(data_rx),
        .busy(busy),
        .scl(scl),
        .sda(sda),
        .sda_ctrl(sda_ctrl)
    );

endmodule