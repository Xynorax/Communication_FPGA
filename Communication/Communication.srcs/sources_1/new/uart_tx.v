`timescale 1ns / 1ps

module uart_tx#(parameter clk_freq= 1000000, parameter baud_rate = 9600)(
    input clk,rst,
    input newd,
    input [7:0] tx_data,
    output reg tx,
    output reg donetx
    );
    
    localparam clk_bit_count = (clk_freq/baud_rate);
    integer clk_count = 0;
    integer counts = 0;
    reg uclk = 0;
    // Uart clock generation
    always @(posedge clk) begin
    if (clk_count < clk_bit_count/2) begin
        clk_count <= clk_count + 1;
    end else begin
        clk_count <= 0;
        uclk <= ~uclk;
    end
    
    end
    
    reg [7:0]din;
    
    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE     = 2'b11;
    reg [1:0]state = IDLE;
    always@(posedge uclk) begin
        if(rst)
            state <= IDLE;
        else begin
            case(state)
                IDLE: begin
                    counts <= 0;
                    tx <= 1'b1;
                    donetx <= 1'b0;
                    
                    if(newd) begin
                        state <= TRANSFER;
                        din <= tx_data;
                        tx <= 1'b0;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                TRANSFER: begin
                    if (counts <= 7) begin
                        counts <= counts + 1;
                        tx <= din[counts];
                        state <= TRANSFER;
                    end
                    else begin
                        counts <= 0;
                        state <= IDLE;
                        tx <= 1'b1;
                        donetx <= 1'b1;
                    end
                end
            endcase
        end            
             
    end
        
endmodule
