// SPI Master Module for Pmod DA2
// 
// This module implements a simple SPI master interface designed for the
// Pmod DA2 Digital-to-Analog converter. The Pmod DA2 requires:
// - 16-bit data transfer (MSB first)
// - Only the last 12 bits are used by the DAC
// - Simple SPI protocol with CS, SCLK, and MOSI
//
// Interface:
//   clk        - System clock input
//   rst_n      - Active low asynchronous reset
//   start      - Pulse high to begin SPI transfer
//   data_in    - 16-bit data to transmit (MSB first)
//   clk_div    - Clock divider value (SPI_CLK = clk / (2 * (clk_div + 1)))
//   busy       - High during active transfer
//   spi_cs_n   - SPI Chip Select (active low)
//   spi_sclk   - SPI Serial Clock
//   spi_mosi   - SPI Master Out Slave In

module spimaster (
    // System interface
    input wire clk,
    input wire rst_n,
    
    // Control interface
    input wire start,
    input wire [15:0] data_in,
    input wire [7:0] clk_div,
    output reg busy,
    
    // SPI interface
    output reg spi_cs_n,
    output reg spi_sclk,
    output reg spi_mosi
);

    // State machine states
    localparam IDLE       = 2'b00;
    localparam TRANSFER   = 2'b01;
    localparam FINISH     = 2'b10;
    
    // Internal registers
    reg [1:0] state;
    reg [1:0] next_state;
    reg [15:0] shift_reg;
    reg [4:0] bit_count;      // Count 16 bits (0-15)
    reg [7:0] clk_count;
    reg sclk_enable;
    reg sclk_internal;
    reg sclk_prev;            // Previous clock state for edge detection
    
    // Clock divider logic - generates SPI clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_count <= 8'h0;
            sclk_internal <= 1'b0;
        end else if (sclk_enable) begin
            if (clk_count >= clk_div) begin
                clk_count <= 8'h0;
                sclk_internal <= ~sclk_internal;
            end else begin
                clk_count <= clk_count + 1'b1;
            end
        end else begin
            clk_count <= 8'h0;
            sclk_internal <= 1'b0;
        end
    end
    
    // State machine - sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // State machine - combinational logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = TRANSFER;
                end
            end
            
            TRANSFER: begin
                if (bit_count == 5'd16 && sclk_internal == 1'b0 && clk_count == 8'h0) begin
                    next_state = FINISH;
                end
            end
            
            FINISH: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // SPI transfer control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'h0;
            bit_count <= 5'd0;
            busy <= 1'b0;
            spi_cs_n <= 1'b1;
            spi_sclk <= 1'b0;
            spi_mosi <= 1'b0;
            sclk_enable <= 1'b0;
            sclk_prev <= 1'b0;
        end else begin
            // Track previous clock state for edge detection
            sclk_prev <= sclk_internal;
            
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    spi_cs_n <= 1'b1;
                    spi_sclk <= 1'b0;
                    spi_mosi <= 1'b0;
                    sclk_enable <= 1'b0;
                    bit_count <= 5'd0;
                    sclk_prev <= 1'b0;
                    
                    if (start) begin
                        shift_reg <= data_in;
                        busy <= 1'b1;
                        spi_cs_n <= 1'b0;  // Assert chip select
                    end
                end
                
                TRANSFER: begin
                    busy <= 1'b1;
                    spi_cs_n <= 1'b0;
                    sclk_enable <= 1'b1;
                    spi_sclk <= sclk_internal;
                    
                    // Set first bit when entering TRANSFER state (bit_count == 0)
                    if (bit_count == 5'd0) begin
                        spi_mosi <= shift_reg[15];
                        shift_reg <= {shift_reg[14:0], 1'b0};
                        bit_count <= bit_count + 1'b1;
                    end
                    // Update MOSI on falling edge of internal clock
                    else if (sclk_prev == 1'b1 && sclk_internal == 1'b0) begin
                        if (bit_count < 5'd16) begin
                            // Transmit MSB first
                            spi_mosi <= shift_reg[15];
                            shift_reg <= {shift_reg[14:0], 1'b0};
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                FINISH: begin
                    busy <= 1'b0;
                    spi_cs_n <= 1'b1;  // De-assert chip select
                    spi_sclk <= 1'b0;
                    spi_mosi <= 1'b0;
                    sclk_enable <= 1'b0;
                    bit_count <= 5'd0;
                end
                
                default: begin
                    busy <= 1'b0;
                    spi_cs_n <= 1'b1;
                    spi_sclk <= 1'b0;
                    spi_mosi <= 1'b0;
                    sclk_enable <= 1'b0;
                    bit_count <= 5'd0;
                end
            endcase
        end
    end

endmodule