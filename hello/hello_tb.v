// Testbench for hello module
`timescale 1ns/1ps

module hello_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    wire [3:0] counter;

    // Instantiate the hello module
    hello uut (
        .clk(clk),
        .rst_n(rst_n),
        .counter(counter)
    );

    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("hello.vcd");
        $dumpvars(0, hello_tb);

        // Reset sequence
        rst_n = 0;
        #20;
        rst_n = 1;

        // Run for some clock cycles
        #200;

        // Display final counter value
        $display("Final counter value: %d", counter);
        
        // End simulation
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst_n=%b counter=%d", $time, rst_n, counter);
    end

endmodule
