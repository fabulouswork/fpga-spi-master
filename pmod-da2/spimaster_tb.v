// Testbench for SPI Master Module
// Tests various scenarios including different clock dividers and data patterns

`timescale 1ns/1ps

module spimaster_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] data_in;
    reg [7:0] clk_div;
    wire busy;
    wire spi_cs_n;
    wire spi_sclk;
    wire spi_mosi;
    
    // Test monitoring variables
    integer bit_counter;
    reg [15:0] captured_data;
    
    // Instantiate the SPI Master
    spimaster uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .clk_div(clk_div),
        .busy(busy),
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi)
    );
    
    // Clock generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Capture transmitted data on MOSI (for verification)
    always @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            captured_data <= {captured_data[14:0], spi_mosi};
            bit_counter <= bit_counter + 1;
        end
    end
    
    // Monitor SPI signals
    always @(negedge spi_cs_n) begin
        $display("Time=%0t: SPI Transfer Started", $time);
        bit_counter = 0;
        captured_data = 16'h0000;
    end
    
    always @(posedge spi_cs_n) begin
        $display("Time=%0t: SPI Transfer Complete - Captured Data: 0x%04h (%d bits)", 
                 $time, captured_data, bit_counter);
    end
    
    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("spimaster.vcd");
        $dumpvars(0, spimaster_tb);
        
        // Initialize signals
        rst_n = 0;
        start = 0;
        data_in = 16'h0000;
        clk_div = 8'd1;  // Default clock divider (SPI_CLK = CLK/4)
        
        $display("========================================");
        $display("SPI Master Testbench Started");
        $display("========================================");
        
        // Reset sequence
        #100;
        rst_n = 1;
        #100;
        
        // Test 1: Send 0xAAAA with clock divider = 1
        $display("\nTest 1: Sending 0xAAAA with clk_div=1");
        data_in = 16'hAAAA;
        clk_div = 8'd1;
        #20;
        start = 1;
        #20;
        start = 0;
        
        // Wait for transfer to complete
        wait(!busy);
        #200;
        
        // Test 2: Send 0x5555 with clock divider = 2 (slower clock)
        $display("\nTest 2: Sending 0x5555 with clk_div=2");
        data_in = 16'h5555;
        clk_div = 8'd2;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 3: Send 0xF0F0 with clock divider = 0 (fastest)
        $display("\nTest 3: Sending 0xF0F0 with clk_div=0");
        data_in = 16'hF0F0;
        clk_div = 8'd0;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 4: Send Pmod DA2 command (12-bit value)
        // Format for Pmod DA2: [15:12] control bits, [11:0] 12-bit DAC value
        // Example: Channel A, unbuffered, 1x gain, active = 0011 + 12-bit value
        $display("\nTest 4: Sending Pmod DA2 command (Channel A, value=0x7FF)");
        data_in = 16'h37FF;  // 0011 0111 1111 1111
        clk_div = 8'd3;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 5: Send maximum value
        $display("\nTest 5: Sending 0xFFFF with clk_div=1");
        data_in = 16'hFFFF;
        clk_div = 8'd1;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 6: Send minimum value
        $display("\nTest 6: Sending 0x0000 with clk_div=1");
        data_in = 16'h0000;
        clk_div = 8'd1;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 7: Back-to-back transfers
        $display("\nTest 7: Back-to-back transfers");
        data_in = 16'h1234;
        clk_div = 8'd1;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #100;
        
        data_in = 16'h5678;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 8: Very fast clock divider (stress test)
        $display("\nTest 8: Very fast clock (clk_div=0, fastest possible)");
        data_in = 16'hDEAD;
        clk_div = 8'd0;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        // Test 9: Slow clock divider
        $display("\nTest 9: Slow clock (clk_div=10)");
        data_in = 16'hBEEF;
        clk_div = 8'd10;
        #20;
        start = 1;
        #20;
        start = 0;
        
        wait(!busy);
        #200;
        
        $display("\n========================================");
        $display("All tests completed successfully!");
        $display("========================================");
        $display("Waveform saved to spimaster.vcd");
        $display("View with: gtkwave spimaster.vcd");
        
        #500;
        $finish;
    end
    
    // Timeout watchdog (prevent infinite simulation)
    initial begin
        #100000;  // 100 microseconds timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end
    
    // Monitor all signal changes
    initial begin
        $monitor("Time=%0t clk=%b rst_n=%b start=%b busy=%b cs_n=%b sclk=%b mosi=%b data_in=0x%04h", 
                 $time, clk, rst_n, start, busy, spi_cs_n, spi_sclk, spi_mosi, data_in);
    end

endmodule
