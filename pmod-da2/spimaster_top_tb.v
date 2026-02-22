// Testbench for SPI Master Top Module
// Tests different operating modes and stimulus control

`timescale 1ns/1ps

module spimaster_top_tb;

    // Testbench signals
    reg clk;
    reg rst_btn;
    reg [1:0] mode_sw;
    reg start_btn;
    reg [3:0] clk_div_sw;
    reg [7:0] data_sw;
    
    wire led_busy;
    wire [1:0] led_mode;
    wire spi_cs_n;
    wire spi_sclk;
    wire spi_mosi;
    
    // Test monitoring
    integer transfer_count;
    reg [15:0] captured_data;
    integer bit_counter;
    
    // Instantiate the top module
    spimaster_top uut (
        .clk(clk),
        .rst_btn(rst_btn),
        .mode_sw(mode_sw),
        .start_btn(start_btn),
        .clk_div_sw(clk_div_sw),
        .data_sw(data_sw),
        .led_busy(led_busy),
        .led_mode(led_mode),
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi)
    );
    
    // Clock generation (50 MHz = 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Capture transmitted data on MOSI
    always @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            captured_data <= {captured_data[14:0], spi_mosi};
            bit_counter <= bit_counter + 1;
        end
    end
    
    // Monitor SPI transfers
    always @(negedge spi_cs_n) begin
        $display("Time=%0t: SPI Transfer #%0d Started", $time, transfer_count + 1);
        bit_counter = 0;
        captured_data = 16'h0000;
    end
    
    always @(posedge spi_cs_n) begin
        transfer_count = transfer_count + 1;
        $display("Time=%0t: SPI Transfer #%0d Complete - Data: 0x%04h", 
                 $time, transfer_count, captured_data);
    end
    
    // Task to simulate button press
    task press_button;
        begin
            start_btn = 1;
            #200;  // Hold for debounce time
            start_btn = 0;
            #100;
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("spimaster_top.vcd");
        $dumpvars(0, spimaster_top_tb);
        
        // Initialize signals
        rst_btn = 0;  // Assert reset (active low)
        start_btn = 0;
        mode_sw = 2'b00;
        clk_div_sw = 4'h1;
        data_sw = 8'h00;
        transfer_count = 0;
        
        $display("========================================");
        $display("SPI Master Top Module Testbench");
        $display("========================================");
        
        // Reset sequence
        #100;
        rst_btn = 1;  // Release reset
        #200;
        
        // Test 1: Manual mode - single transfer
        $display("\n=== Test 1: Manual Mode - Single Transfer ===");
        mode_sw = 2'b00;  // Manual mode
        data_sw = 8'hAA;
        clk_div_sw = 4'h1;
        #100;
        
        $display("Pressing start button...");
        press_button();
        
        // Wait for transfer to complete
        wait(!led_busy);
        #500;
        
        // Test 2: Manual mode - different data
        $display("\n=== Test 2: Manual Mode - Different Data ===");
        data_sw = 8'h55;
        #100;
        $display("Pressing start button...");
        press_button();
        wait(!led_busy);
        #500;
        
        // Test 3: Manual mode - multiple button presses
        $display("\n=== Test 3: Manual Mode - Multiple Transfers ===");
        data_sw = 8'h12;
        #100;
        press_button();
        wait(!led_busy);
        #200;
        
        data_sw = 8'h34;
        press_button();
        wait(!led_busy);
        #200;
        
        data_sw = 8'hFF;
        press_button();
        wait(!led_busy);
        #500;
        
        // Test 4: Auto pattern mode
        $display("\n=== Test 4: Auto Pattern Mode ===");
        $display("Switching to auto pattern mode (mode=01)");
        mode_sw = 2'b01;  // Auto pattern mode
        clk_div_sw = 4'h0;  // Fast clock
        
        // Wait for a few automatic transfers
        repeat(3) begin
            @(posedge spi_cs_n);  // Wait for transfer to complete
            #1000;
        end
        #2000;
        
        // Test 5: Ramp mode
        $display("\n=== Test 5: Ramp Mode ===");
        $display("Switching to ramp mode (mode=10)");
        mode_sw = 2'b10;  // Ramp mode
        
        // Wait for a few ramp increments
        repeat(3) begin
            @(posedge spi_cs_n);
            #1000;
        end
        #2000;
        
        // Test 6: Sine wave mode
        $display("\n=== Test 6: Sine Wave Mode ===");
        $display("Switching to sine wave mode (mode=11)");
        mode_sw = 2'b11;  // Sine wave mode
        
        // Wait for a few sine wave samples
        repeat(3) begin
            @(posedge spi_cs_n);
            #1000;
        end
        #2000;
        
        // Test 7: Clock divider changes
        $display("\n=== Test 7: Clock Divider Changes ===");
        mode_sw = 2'b00;  // Back to manual mode
        
        $display("Testing with clk_div=0 (fastest)");
        clk_div_sw = 4'h0;
        data_sw = 8'hAA;
        press_button();
        wait(!led_busy);
        #500;
        
        $display("Testing with clk_div=5 (moderate)");
        clk_div_sw = 4'h5;
        data_sw = 8'h55;
        press_button();
        wait(!led_busy);
        #500;
        
        $display("Testing with clk_div=10 (slow)");
        clk_div_sw = 4'hA;
        data_sw = 8'hF0;
        press_button();
        wait(!led_busy);
        #500;
        
        // Test 8: Reset during operation
        $display("\n=== Test 8: Reset During Operation ===");
        mode_sw = 2'b00;
        clk_div_sw = 4'h3;
        data_sw = 8'hBE;
        
        press_button();
        #300;  // Reset during transfer
        
        $display("Asserting reset during transfer...");
        rst_btn = 0;
        #200;
        rst_btn = 1;
        #500;
        
        // Confirm system recovers
        $display("Testing recovery after reset...");
        data_sw = 8'hEF;
        press_button();
        wait(!led_busy);
        #500;
        
        $display("\n========================================");
        $display("Test Summary:");
        $display("Total SPI Transfers: %0d", transfer_count);
        $display("All tests completed successfully!");
        $display("========================================");
        $display("Waveform saved to spimaster_top.vcd");
        $display("View with: gtkwave spimaster_top.vcd");
        
        #1000;
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500000;  // 500 microseconds timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end
    
    // Monitor mode changes
    always @(mode_sw) begin
        case (mode_sw)
            2'b00: $display("Mode changed to: MANUAL (00)");
            2'b01: $display("Mode changed to: AUTO PATTERN (01)");
            2'b10: $display("Mode changed to: RAMP (10)");
            2'b11: $display("Mode changed to: SINE WAVE (11)");
        endcase
    end

endmodule
