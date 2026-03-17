`timescale 1ns / 1ps

module device#(parameter clk_freq= 1000000, parameter baud_rate = 9600)(
    input clk, rst,
    input rx,
    output tx
    );
    reg newd;
    reg [7:0]tx_data;
    wire done_tx;
    wire donerx;
    wire [7:0]rxdata;
    uart_tx#(clk_freq, baud_rate) uart_tx_inst(clk, rst, newd, tx_data, tx, done_tx);
    uart_rx#(clk_freq, baud_rate) uart_rx_inst(clk, rst, rx, donerx, rxdata);
endmodule
