`timescale 1ns / 1ps

module tb_uart();
    reg rst = 0;
    reg newd = 0;
    reg dintx;
    wire tx;
    reg rx = 1;
    reg [7:0]tx_data;
    reg [7:0]tx_data_expected;
    integer i;
    integer j;
    reg clk = 0;
    wire donerx;
    wire [7:0]rxdata;
    wire donetx;
    reg [7:0]rx_data_expected;
    
    uart_tx #(1000000, 9600) uart_tx_inst(.clk(clk), 
    .rst(rst), .newd(newd),.tx_data(tx_data), .tx(tx), .donetx(donetx));
    
    uart_rx uart_rx_inst(.clk(clk), .rst(rst), 
    .rx(rx), .donerx(donerx), .rxdata(rxdata));
    
    always #5 clk = ~clk;
    initial begin
    
    rst = 1;
    #10
    rst = 0;
    
    for(i = 0; i<10; i=i+1) begin
        rst = 0;
        newd = 1;
        tx_data = $urandom();
        wait (tx==0);
        @(posedge clk);
        for(j= 0; j<8; j=j+1) begin
            @(posedge uart_tx_inst.uclk);
            tx_data_expected = {tx, tx_data_expected[7:1]};
            
        end
        @(posedge donetx);
    end
    
    for(i=0; i<10; i= i+1) begin
        rst = 0;
        newd = 0;
        rx = 1'b0;
        for(j= 0; j< 8; j=j+1) begin
            @(posedge uart_tx_inst.uclk);
            rx = $urandom;
            rx_data_expected = {rx, rx_data_expected[7:1]};
        end
        @(posedge donerx);
    end
    
    $finish;
    end
    
    
endmodule
