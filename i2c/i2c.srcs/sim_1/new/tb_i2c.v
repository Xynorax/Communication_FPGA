`timescale 1ns / 1ps

module tb_i2c;

    reg clk;
    reg rst;
    reg start;
    reg [6:0] slave_addr;
    reg rw;
    reg [7:0] data_in;
    wire [7:0] slave1_data;
    wire [7:0] slave2_data;
    wire sda;
    wire scl;
    wire slave1_ready;
    wire slave2_ready;

    wire sda_master, sda_slave1, sda_slave2;
    wire sda_ctrl_master, sda_ctrl_slave1, sda_ctrl_slave2;
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    reg sda_master_reg;
    assign sda_master = sda_master_reg ? 1'b0 : 1'bz;
    assign sda = (sda_ctrl_master == 1 || sda_ctrl_slave1 == 1 || sda_ctrl_slave2 == 1) ? 1'b0 : 1'b1; // Acts as pull up resistor
    i2c_master uut_master(
        .clk(clk),
        .rst(rst),
        .start(start),
        .address(slave_addr),
        .rw(rw),
        .data_in(data_in),
        .data_out(),
        .busy(),
        .sda(sda),
        .scl(scl),
        .sda_ctrl(sda_ctrl_master)
    );

    i2c_slave slave1(
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .slave_addr(7'h50),
        .data_out(slave1_data),
        .data_ready(slave1_ready),
        .sda_ctrl(sda_ctrl_slave1),
        .done(done_slave1)
    );

    i2c_slave slave2(
        .clk(clk),
        .rst(rst),
        .sda(sda),
        .scl(scl),
        .slave_addr(7'h60),
        .data_out(slave2_data),
        .data_ready(slave2_ready),
        .sda_ctrl(sda_ctrl_slave2),
        .done(done_slave2)
    );

    initial begin
        rst = 1;
        start = 0;
        slave_addr = 7'h50;
        rw = 0; // write
        data_in = 8'hA5;
        sda_master_reg = 1;

        #20;
        rst = 0;

        // Write to slave 1
        
        #20;
        start = 1;
        #10 start = 0;
        
        wait (done_slave1);
        #500000;
        // Write to slave 2
        slave_addr = 7'h60;
        data_in = 8'h3C;
        #20;
        start = 1;
        #10 start = 0;
        wait (done_slave2);

        $display("Slave 1 received: %h, ready: %b", slave1_data, slave1_ready);
        $display("Slave 2 received: %h, ready: %b", slave2_data, slave2_ready);

        #100;
        $stop;
    end

endmodule