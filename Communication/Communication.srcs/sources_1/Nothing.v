module uart_rx_top (
    input clk, rst, baud_pulse, rx, 
    input sticky_parity, eps, pen,
    input [1:0] wls,
    output reg push,
    output reg pe, fe, bi,
    output reg [7:0] dout
);

    typedef enum logic [2:0] {IDLE = 3'd0, START = 3'd1, READ = 3'd2, PARITY = 3'd3, STOP = 3'd4} state_type;
    state_type state;

    // --- Synchronization & Edge Detection ---
    reg rx_sync_0, rx_sync_1; // Double flop to prevent metastability
    reg rx_prev;
    wire falling_edge;

    always @(posedge clk) begin
        rx_sync_0 <= rx;
        rx_sync_1 <= rx_sync_0;
        rx_prev   <= rx_sync_1;
    end
    assign falling_edge = (rx_prev == 1'b1 && rx_sync_1 == 1'b0);

    // --- Internal Registers ---
    reg [3:0] count;
    reg [2:0] bitcnt;
    reg [7:0] shift_reg;
    
    // Calculate total bits to read based on WLS (Word Length Select)
    // 2'b00=5 bits, 2'b01=6 bits, 2'b10=7 bits, 2'b11=8 bits
    wire [2:0] max_bits = (wls == 2'b00) ? 3'd4 : 
                          (wls == 2'b01) ? 3'd5 : 
                          (wls == 2'b10) ? 3'd6 : 3'd7;

    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            push <= 1'b0;
            pe <= 1'b0; fe <= 1'b0; bi <= 1'b0;
            dout <= 8'h00;
            count <= 4'd0;
        end else begin
            push <= 1'b0; // Pulse output

            if (baud_pulse) begin
                case (state)
                    IDLE: begin
                        if (falling_edge) begin
                            state <= START;
                            count <= 4'd15;
                        end
                    end

                    START: begin
                        if (count == 4'd7) begin
                            if (rx_sync_1 != 1'b0) begin // Verify start bit is still low
                                state <= IDLE;
                            end
                        end
                        if (count == 4'd0) begin
                            state <= READ;
                            count <= 4'd15;
                            bitcnt <= max_bits;
                        end else begin
                            count <= count - 1;
                        end
                    end

                    READ: begin
                        if (count == 4'd7) begin
                            // Sample in the middle of the bit
                            shift_reg <= {rx_sync_1, shift_reg[7:1]};
                        end
                        
                        if (count == 4'd0) begin
                            count <= 4'd15;
                            if (bitcnt == 3'd0) begin
                                // Adjust shift register result based on WLS
                                case(wls)
                                    2'b00: dout <= shift_reg[7:3];
                                    2'b01: dout <= shift_reg[7:2];
                                    2'b10: dout <= shift_reg[7:1];
                                    2'b11: dout <= shift_reg;
                                endcase
                                state <= (pen) ? PARITY : STOP;
                            end else begin
                                bitcnt <= bitcnt - 1;
                            end
                        end else begin
                            count <= count - 1;
                        end
                    end

                    PARITY: begin
                        if (count == 4'd7) begin
                            // Parity calculation logic
                            case ({sticky_parity, eps})
                                2'b00: pe <= (rx_sync_1 == ^dout);    // Odd: fail if rx == XOR(data)
                                2'b01: pe <= (rx_sync_1 != ^dout);    // Even: fail if rx != XOR(data)
                                2'b10: pe <= (rx_sync_1 != 1'b1);     // Mark
                                2'b11: pe <= (rx_sync_1 != 1'b0);     // Space
                            endcase
                        end
                        if (count == 4'd0) begin
                            state <= STOP;
                            count <= 4'd15;
                        end else begin
                            count <= count - 1;
                        end
                    end

                    STOP: begin
                        if (count == 4'd7) begin
                            fe <= (rx_sync_1 == 1'b0); // Frame error if stop bit is low
                            push <= 1'b1;              // Data ready for FIFO
                        end
                        if (count == 4'd0) begin
                            state <= IDLE;
                        end else begin
                            count <= count - 1;
                        end
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule