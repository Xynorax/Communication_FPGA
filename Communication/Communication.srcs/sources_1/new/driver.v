`timescale 1ns / 1ps
`include "uart_defs.vh"
module driver#(parameter clk_freq= 1000000, parameter baud_rate = 9600)(
    input clk, rst, wr, rd,
    input rx,
    input [2:0] addr,
    input [7:0] din,
    output tx,
    output [7:0] dout
    );
     wire baud_pulse, pen, thre, stb; 
 
     wire tx_fifo_pop;
     wire [7:0] tx_fifo_out;
     wire tx_fifo_push;
     
     wire r_oe, r_pe, r_fe, r_bi;
     wire rx_fifo_push, rx_fifo_pop;
     wire tx_fifo_empty, rx_fifo_empty, overrun;
     wire [31:0] csr;
     wire [7:0] fcr, lcr, lsr, scr;

     assign fcr = csr[31:24];
     assign lcr = csr[23:16];
     assign lsr = csr[15:8];
     assign scr = csr[7:0];

    uart_regs uart_regs_inst (
    .clk (clk),
    .rst (rst),
    .wr_i (wr),
    .rd_i (rd),
    
    .rx_fifo_empty_i (rx_fifo_empty),
    .rx_oe (overrun),
    .rx_pe (r_pe),
    .rx_fe (r_fe),
    .rx_bi (r_bi),
    
    .addr_i (addr),
    .din (din),
    .tx_push_o (tx_fifo_push),
    .rx_pop_o (rx_fifo_pop),
    .baud_out (baud_pulse),
    .tx_rst (tx_rst),
    .rx_rst (rx_rst),
    .rx_fifo_threshold (rx_fifo_threshold),
    .dout_o (dout),
    .csr_o (csr),
    .rx_fifo_in(rx_fifo_out)
);
uart_tx uart_tx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .pen (lcr[`LCR_PEN]),
    .thre (tx_fifo_empty),
    .stb (lcr[`LCR_STB]),
    .sticky_parity (lcr[`LCR_STICK]),
    .eps (lcr[`LCR_EPS]),
    .set_break (lcr[`LCR_BREAK]),
    .din (tx_fifo_out),
    .wls (lcr[`LCR_WLS]),
    .pop (tx_fifo_pop),
    .sreg_empty (),
    .tx (tx)
);

fifo tx_fifo_inst (
    .rst (rst),
    .clk (clk),
    .en (fcr[`FCR_ENA]),
    .push_in (tx_fifo_push),
    .pop_in (tx_fifo_pop),
    .din (din),
    .dout (tx_fifo_out),
    .empty (tx_fifo_empty), /// fifo empty ier
    .full (),
    .overrun (overrun),
    .underrun (),
    .threshold (4'h0),
    .thre_trigger ()
);
 uart_rx uart_rx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .rx (rx),
    .sticky_parity (lcr[`LCR_STICK]),
    .eps (lcr[`LCR_EPS]),
    .pen (lcr[`LCR_PEN]),
    .wls (lcr[`LCR_WLS]),
    .push (rx_fifo_push),
    .pe (r_pe),
    .fe (r_fe),
    .bi (r_bi),
    .dout(rx_out)
);
 
 
fifo rx_fifo_inst (
    .rst (rst),
    .clk (clk),
    .en (fcr[`FCR_ENA]),
    .push_in (rx_fifo_push),
    .pop_in (rx_fifo_pop),
    .din (rx_out),
    .dout (rx_fifo_out),
    .empty (rx_fifo_empty), 
    .full (),
    .overrun (),
    .underrun (),
    .threshold (rx_fifo_threshold),
    .thre_trigger ()
);
endmodule
