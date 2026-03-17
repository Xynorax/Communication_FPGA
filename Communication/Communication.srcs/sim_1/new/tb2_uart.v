`timescale 1ns / 1ps

module tb2_uart;
    localparam clk_freq = 998400;
    localparam clk2_freq = 499200;
    // Calculate period in nanoseconds (10^9 / freq)
    localparam clk_period = 1000000000.0/clk_freq;
    localparam clk2_period = 1000000000.0/clk2_freq;
    localparam baud_rate = 9600;
    reg clk = 0;
    reg clk2 = 0;
    reg rst;
    integer i;
    integer j;
    wire tx1, tx2;
    reg rd1,rd2, wr1, wr2;
    reg [7:0] din1, din2;
    reg [2:0] addr1, addr2;
    driver #(clk_freq,baud_rate) dut1  (clk, rst, wr1, rd1,tx1,addr1, din1, tx2, dout);
    driver #(clk2_freq,baud_rate) dut2 (clk, rst, wr2, rd2,tx2,addr2, din2, tx1, dout);
    always #(clk_period/2.0) clk = ~clk;
    always #(clk2_period/2.0) clk2 = ~clk2;
    initial begin
        rst = 0;
        clk = 0;
        wr1 = 0;
        rd1 = 0;
        addr1 = 0;
        din1 = 0;
    end
    initial begin
        #1000000
        rst <= 1;
        #2000000
        rst <= 0;
        #1000000
        // set dlab to 1
        @(negedge clk);
        wr1   <= 1;
        addr1 = 3'h3;
        din1  = 8'b1000_0000;
         
        // Set the Divisor = 0x0108
        @(negedge clk);
        addr1 = 3'h0;
        din1  = 8'b0000_1000;
         
        @(negedge clk);
        addr1 = 3'h1;
        din1  = 8'b0000_0001;
        @(negedge clk);
        addr1 = 3'h3;
        din1  = 8'b0000_1100;
        
        ///// dlab = 0, wls = 00(5-bits), stb = 1 (single bit dur), pen = 1, eps =0(odd), sp = 0
        @(negedge clk);
        addr1 = 3'h3;
        din1  = 8'b0000_1100;

        // Write to FIFO
        @(negedge clk);
        addr1 = 3'h0;
        din1  = 8'b1111_0000;///10000 -> parity = 0, 
        
        // Remove wr
        @(negedge clk);
        wr1 = 0;
        @(posedge dut1.uart_tx_inst.sreg_empty);
        repeat(48) @(posedge dut1.uart_tx_inst.baud_pulse);
        $display("Test completed");
        $stop;
    end
endmodule
