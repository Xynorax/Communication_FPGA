`timescale 1ns / 1ps

module uart_rx#(parameter clk_freq = 1000000, parameter baud_rate=9600)(
    input clk, rst,
    input rx,
    output reg donerx,
    output reg [7:0]rxdata
    );
    localparam clk_bit_count = (clk_freq/baud_rate);
    integer clk_count = 0;
    integer counts = 0;
    reg uclk = 0;
    reg [1:0] state = 0;
    
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    
    // Uart clock gen
    always@(posedge clk) begin
        if(clk_count < clk_bit_count/2) begin
            clk_count <= clk_count + 1;
        end else begin
            clk_count <= 0;
            uclk <= ~uclk;
        end
    end
    always @(posedge uclk) begin
        if(rst) begin
            rxdata <= 8'h00;
            donerx <= 0;
            counts <= 0;
        end else begin
            case(state)
                IDLE: begin
                    donerx <= 1'b0;
                    if (rx == 1'b0) 
                        state <= START;
                    else
                        state <= IDLE;
                end
                
                START: begin
                    if (counts <= 7) begin
                        counts <= counts + 1;
                        rxdata <= {rx, rxdata[7:1]};
                    end else begin
                        counts <= 0;
                        donerx <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
