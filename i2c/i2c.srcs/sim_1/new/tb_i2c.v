`timescale 1ns / 1ps

module tb_i2c;

    reg clk;
    reg rst;


    reg wr_en;
    reg rd_en;
    reg [2:0] addr;
    reg [2:0] slave_reg_addr;
    reg [7:0] wdata;
    wire [7:0] rdata;


    wire sda;
    wire scl;

    wire [7:0] slave1_data;
    wire [7:0] slave2_data;
    reg slave1_wr_en, slave1_rd_en;
    reg slave2_wr_en, slave2_rd_en;
    reg [7:0] slave1_wdata, slave2_wdata;
    wire [7:0] slave1_rdata, slave2_rdata;
    wire slave1_ready;
    wire slave2_ready;
    wire done_slave1, done_slave2;

    wire sda_ctrl_master, sda_ctrl_slave1, sda_ctrl_slave2;

    initial clk = 0;
    always #5 clk = ~clk;

    // Acts like pull up resistor
    assign sda = (sda_ctrl_master || sda_ctrl_slave1 || sda_ctrl_slave2) ? 1'b0 : 1'b1;


    i2c_master_driver uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .sda(sda),
        .scl(scl),
        .sda_ctrl(sda_ctrl_master)
    );

    i2c_slave_driver slave1(
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .sda_ctrl(sda_ctrl_slave1),
        
        .reg_addr(slave_reg_addr),
        .wr_en(slave1_wr_en),
        .rd_en(slave1_rd_en),
        .wdata(slave1_wdata),
        .rdata(slave1_rdata),
        .done(done_slave1)
    );

    i2c_slave_driver slave2(
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .sda_ctrl(sda_ctrl_slave2),
        .reg_addr(slave_reg_addr),
        .wr_en(slave2_wr_en),
        .rd_en(slave2_rd_en),
        .wdata(slave2_wdata),
        .rdata(slave2_rdata),
        .done(done_slave2)
    );

    task write_reg(input [2:0] a, input [7:0] d, input [0:1] driver); // 00 for master, 01 for slave1, 10 for slave2
    begin
        @(posedge clk);
        if(driver == 2'b00) begin
            wr_en <= 1;
            addr  <= a;
            wdata <= d;
        end
        else if (driver == 2'b01) begin
            slave1_wr_en <= 1;
            slave_reg_addr <= a;
            slave1_wdata <= d;
        end
        else if (driver == 2'b10) begin
            slave2_wr_en <= 1;
            slave_reg_addr <= a;
            slave2_wdata <= d;
        end
        @(posedge clk);
        wr_en <= 0;
        slave1_wr_en <= 0;
        slave2_wr_en <= 0;
    end
    endtask

    initial begin
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        addr = 0;
        wdata = 0;

        #20;
        rst = 0;
        // Set slaves addresses registers
        write_reg(3'd2, 8'h50, 2'b01);
        write_reg(3'd2, 8'h60, 2'b10);
        
        // Write to Slave 1 (Address: 0x50)
        write_reg(3'd2, 8'h50, 0); // ADDR
        write_reg(3'd3, 8'hA5, 0); // DATA
        write_reg(3'd0, 8'b00000001, 0); 

        wait(done_slave1);
        #10000;
        // Write to Slave 2 (Address: 0x60)
        write_reg(3'd2, 8'h60, 0);
        write_reg(3'd3, 8'h3C, 0);
        write_reg(3'd0, 8'b00000001, 0);

        wait(done_slave2);

        $display("Slave 1 received: %h, ready: %b", slave1_data, slave1_ready);
        $display("Slave 2 received: %h, ready: %b", slave2_data, slave2_ready);

        #100;
        $stop;
    end

endmodule