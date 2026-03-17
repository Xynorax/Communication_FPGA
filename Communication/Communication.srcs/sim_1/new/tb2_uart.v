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
    device #(clk_freq,baud_rate) dut1(.clk(clk), .rst(rst), .tx(tx1), .rx(tx2));
    device #(clk2_freq,baud_rate) dut2(.clk(clk2), .rst(rst), .tx(tx2), .rx(tx1));
    
    always #(clk_period/2.0) clk = ~clk;
    always #(clk2_period/2.0) clk2 = ~clk2;
    
    initial begin
        #1000000
        rst <= 1;
        #2000000
        rst <= 0;
        #1000000
        dut1.newd <= 1;
        for(i= 0; i<20; i=i+1) begin
            dut1.tx_data = $urandom();
            @(posedge dut1.done_tx);
        end
        dut1.newd <= 0;
        dut2.newd <= 1;
        for(i= 0; i<20; i=i+1) begin
            dut2.tx_data = $urandom();
            @(posedge dut2.done_tx);
        end
        dut2.newd <= 0;
        $display("Test completed");
        $finish;
    end
endmodule
