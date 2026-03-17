`timescale 1ns / 1ps

module uart_tx#(parameter clk_freq= 1000000, parameter baud_rate = 9600)(
    input clk, rst, baud_pulse, pen, thre, 
    stb, sticky_parity, eps, set_break,
    input [7:0] din,
    input [1:0] wls,
    output reg pop, sreg_empty,
    output tx
    );
    
    localparam clk_bit_count = (clk_freq/baud_rate);
    integer clk_count = 0;
    integer counts = 0;
    reg uclk = 0;

    
    reg [7:0] shft_reg;
    reg tx_data;
    reg d_parity;
    reg [2:0] bitcnt = 0;
    reg [4:0] count = 5'd15;
    reg parity_out;
    
    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam PARITY     = 2'b11;
    reg [1:0]state = IDLE;
    always@(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            count <= 5'd15;
            bitcnt <= 0;
            shft_reg   <= 8'bxxxxxxxx;
            pop        <= 1'b0;
            sreg_empty <= 1'b0;
            tx_data    <= 1'b1; 
        end else if(baud_pulse) begin
            case(state)
                IDLE: begin
                    if(thre == 1'b0) begin
                        if(count != 0) begin
                            count <= count - 1;
                            state <= IDLE;
                        end else begin
                            count <=5'd15;
                            state <= START;
                            bitcnt <= {1'b1, wls};
                            pop <= 1'b1;
                            shft_reg <= din;
                            sreg_empty <= 1'b0;
                            tx_data <= 1'b0; // Set start to 0
                        end


                    end
                end
                
                START: begin
                    if(count != 0) begin
                        count <= count - 1;
                        state <= START;
                    end else begin
                        count  <= 5'd15;
                        state  <= TRANSFER;
                        case(wls)
                         2'b00: d_parity <= ^shft_reg[4:0]; 
                         2'b01: d_parity <= ^shft_reg[5:0];  
                         2'b10: d_parity <= ^shft_reg[6:0];  
                         2'b11: d_parity <= ^shft_reg[7:0];           
                         endcase
 
                        tx_data    <= shft_reg[0]; 
                        shft_reg   <= shft_reg >> 1; 
                        
                        pop        <= 1'b0;
                    end
                end
                TRANSFER: begin
                    case({sticky_parity, eps})
                        2'b00: parity_out <= ~d_parity;
                        2'b01: parity_out <= d_parity;
                        2'b10: parity_out <= 1'b1;
                        2'b11: parity_out <= 1'b0;
                        endcase
                    if(bitcnt != 0)
                          begin
                                if(count != 0)
                                  begin
                                  count <= count - 1;
                                  state <= TRANSFER;  
                                  end
                                else
                                  begin
                                  count <= 5'd15;
                                  bitcnt <= bitcnt - 1;
                                  tx_data    <= shft_reg[0]; 
                                  shft_reg   <= shft_reg >> 1;
                                  state <= TRANSFER;
                                  end
                             end
                       else
                          begin
                                
                                if(count != 0)
                                  begin
                                  count <= count - 1;
                                  state <= TRANSFER;  
                                  end
                                else
                                  begin
                                   count <= 5'd15;
                                   sreg_empty <= 1'b1;
                                  
                                      if(pen == 1'b1)
                                       begin
                                         state <= PARITY;
                                         count <= 5'd15;
                                         tx_data <= parity_out;
                                       end  
                               
                                      else
                                       begin
                                         tx_data <= 1'b1;
                                         count   <= (stb == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd23 : 5'd31;
                                         state   <= IDLE;
                                       end  
                                  end
                        end
                end
                PARITY: begin
                    if(count != 0) begin
                        count<= count - 1;
                        state <= PARITY;
                    end else begin
                        tx_data <= 1'b1;
                        count   <= (stb == 1'b0 )? 5'd15 :(wls == 2'b00) ? 5'd17 : 5'd31; // Stop period 
                        state <= IDLE;
                    end
                end
            endcase
        end            
             
    end
    assign tx = tx_data;
endmodule
