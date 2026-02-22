// Top-Level FPGA Module for SPI Master with Controller
// 
// This module instantiates the spimaster and provides stimulus control
// suitable for FPGA deployment. It includes:
// - Automatic pattern generation
// - Manual control via buttons/switches
// - Status LEDs
// - Configurable clock divider
//
// Typical FPGA Board Connections:
//   clk          - System clock (e.g., 50 MHz, 100 MHz)
//   rst_btn      - Reset button (active low)
//   mode_sw      - Mode select switches [1:0]
//   start_btn    - Manual start button
//   clk_div_sw   - Clock divider switches [3:0]
//   data_sw      - Manual data input switches [7:0]
//   led_busy     - Busy status LED
//   led_mode     - Mode indicator LEDs [1:0]
//   spi_cs_n     - SPI Chip Select to PMOD
//   spi_sclk     - SPI Clock to PMOD
//   spi_mosi     - SPI MOSI to PMOD

module spimaster_top (
    // System interface
    input wire clk,              // System clock input
    input wire rst_btn,          // Reset button (active low)
    
    // Control interface
    input wire [1:0] mode_sw,    // Operating mode selector
                                 // 00 = Manual mode
                                 // 01 = Auto pattern mode
                                 // 10 = Ramp mode
                                 // 11 = Sine wave mode
    input wire start_btn,        // Manual start button (active high)
    input wire [3:0] clk_div_sw, // Clock divider selector (0-15)
    input wire [7:0] data_sw,    // Manual data input (lower 8 bits)
    
    // Status outputs
    output wire led_busy,        // Busy indicator LED
    output wire [1:0] led_mode,  // Mode indicator LEDs
    
    // SPI outputs
    output wire spi_cs_n,        // SPI Chip Select
    output wire spi_sclk,        // SPI Clock
    output wire spi_mosi         // SPI MOSI
);

    // Button debouncing and edge detection
    reg [19:0] debounce_counter;
    reg start_btn_sync, start_btn_prev;
    reg rst_btn_sync;
    wire start_pulse;
    wire rst_n;
    
    // SPI control signals
    reg spi_start;
    reg [15:0] spi_data;
    wire spi_busy;
    
    // Pattern generation
    reg [15:0] pattern_data;
    reg [23:0] auto_counter;     // Counter for automatic pattern generation
    reg [11:0] ramp_value;       // 12-bit ramp value for DAC
    reg [7:0] sine_index;        // Index for sine wave lookup
    
    // Reset synchronization and inversion (button is active low)
    always @(posedge clk) begin
        rst_btn_sync <= rst_btn;
    end
    assign rst_n = rst_btn_sync;
    
    // Debounce and edge detect start button
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_btn_sync <= 1'b0;
            start_btn_prev <= 1'b0;
            debounce_counter <= 20'd0;
        end else begin
            start_btn_prev <= start_btn_sync;
            
            if (start_btn != start_btn_sync) begin
                if (debounce_counter < 20'd999999) begin  // ~20ms at 50MHz
                    debounce_counter <= debounce_counter + 1'b1;
                end else begin
                    start_btn_sync <= start_btn;
                    debounce_counter <= 20'd0;
                end
            end else begin
                debounce_counter <= 20'd0;
            end
        end
    end
    
    // Rising edge detection on start button
    assign start_pulse = (start_btn_sync && !start_btn_prev);
    
    // Automatic pattern counter (generates new pattern every ~167ms at 50MHz)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            auto_counter <= 24'd0;
        end else if (mode_sw != 2'b00) begin  // Only count in auto modes
            if (auto_counter >= 24'd8388607) begin  // ~167ms at 50MHz
                auto_counter <= 24'd0;
            end else begin
                auto_counter <= auto_counter + 1'b1;
            end
        end else begin
            auto_counter <= 24'd0;
        end
    end
    
    // Ramp pattern generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ramp_value <= 12'd0;
        end else if (mode_sw == 2'b10 && auto_counter == 24'd0 && !spi_busy) begin
            ramp_value <= ramp_value + 12'd64;  // Increment by 64 each time
        end
    end
    
    // Sine wave index generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sine_index <= 8'd0;
        end else if (mode_sw == 2'b11 && auto_counter == 24'd0 && !spi_busy) begin
            sine_index <= sine_index + 8'd4;  // Step through sine table
        end
    end
    
    // Sine wave lookup table (simplified 64-entry table for 12-bit output)
    function [11:0] sine_lookup;
        input [7:0] index;
        reg [5:0] table_index;
        begin
            table_index = index[7:2];  // Use upper 6 bits for 64 entries
            case (table_index)
                6'd0:  sine_lookup = 12'd2048;  // Center (0 degrees)
                6'd1:  sine_lookup = 12'd2448;
                6'd2:  sine_lookup = 12'd2831;
                6'd3:  sine_lookup = 12'd3185;
                6'd4:  sine_lookup = 12'd3495;
                6'd5:  sine_lookup = 12'd3750;
                6'd6:  sine_lookup = 12'd3939;
                6'd7:  sine_lookup = 12'd4056;
                6'd8:  sine_lookup = 12'd4095;  // Peak (90 degrees)
                6'd9:  sine_lookup = 12'd4056;
                6'd10: sine_lookup = 12'd3939;
                6'd11: sine_lookup = 12'd3750;
                6'd12: sine_lookup = 12'd3495;
                6'd13: sine_lookup = 12'd3185;
                6'd14: sine_lookup = 12'd2831;
                6'd15: sine_lookup = 12'd2448;
                6'd16: sine_lookup = 12'd2048;  // Center (180 degrees)
                6'd17: sine_lookup = 12'd1648;
                6'd18: sine_lookup = 12'd1265;
                6'd19: sine_lookup = 12'd911;
                6'd20: sine_lookup = 12'd601;
                6'd21: sine_lookup = 12'd346;
                6'd22: sine_lookup = 12'd157;
                6'd23: sine_lookup = 12'd40;
                6'd24: sine_lookup = 12'd0;     // Trough (270 degrees)
                6'd25: sine_lookup = 12'd40;
                6'd26: sine_lookup = 12'd157;
                6'd27: sine_lookup = 12'd346;
                6'd28: sine_lookup = 12'd601;
                6'd29: sine_lookup = 12'd911;
                6'd30: sine_lookup = 12'd1265;
                6'd31: sine_lookup = 12'd1648;
                default: sine_lookup = 12'd2048;  // Repeat pattern
            endcase
        end
    endfunction
    
    // Pattern selection based on mode
    always @(*) begin
        case (mode_sw)
            2'b00: begin
                // Manual mode - use switch inputs
                pattern_data = {8'h30, data_sw};  // Prepend control bits for Pmod DA2
            end
            
            2'b01: begin
                // Auto pattern mode - cycling patterns
                case (auto_counter[23:21])
                    3'd0: pattern_data = 16'h3000;  // Low value
                    3'd1: pattern_data = 16'h37FF;  // Mid value
                    3'd2: pattern_data = 16'h3FFF;  // High value
                    3'd3: pattern_data = 16'h3AAA;  // Pattern 1
                    3'd4: pattern_data = 16'h3555;  // Pattern 2
                    3'd5: pattern_data = 16'h3F0F;  // Pattern 3
                    3'd6: pattern_data = 16'h30F0;  // Pattern 4
                    3'd7: pattern_data = 16'h3FFF;  // Max value
                endcase
            end
            
            2'b10: begin
                // Ramp mode - incrementing value
                pattern_data = {4'h3, ramp_value};  // 0x3 control bits + 12-bit ramp
            end
            
            2'b11: begin
                // Sine wave mode
                pattern_data = {4'h3, sine_lookup(sine_index)};
            end
            
            default: begin
                pattern_data = 16'h0000;
            end
        endcase
    end
    
    // Control state machine for SPI transfers
    localparam CTRL_IDLE = 2'b00;
    localparam CTRL_START = 2'b01;
    localparam CTRL_WAIT = 2'b10;
    
    reg [1:0] ctrl_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_state <= CTRL_IDLE;
            spi_start <= 1'b0;
            spi_data <= 16'h0000;
        end else begin
            case (ctrl_state)
                CTRL_IDLE: begin
                    spi_start <= 1'b0;
                    
                    // Start transfer on button press or automatic trigger
                    if ((mode_sw == 2'b00 && start_pulse) ||
                        (mode_sw != 2'b00 && auto_counter == 24'd0 && !spi_busy)) begin
                        spi_data <= pattern_data;
                        ctrl_state <= CTRL_START;
                    end
                end
                
                CTRL_START: begin
                    spi_start <= 1'b1;
                    ctrl_state <= CTRL_WAIT;
                end
                
                CTRL_WAIT: begin
                    spi_start <= 1'b0;
                    if (!spi_busy) begin
                        ctrl_state <= CTRL_IDLE;
                    end
                end
                
                default: begin
                    ctrl_state <= CTRL_IDLE;
                    spi_start <= 1'b0;
                end
            endcase
        end
    end
    
    // Instantiate SPI Master
    spimaster spi_inst (
        // System interface
        .clk(clk),
        .rst_n(rst_n),
        
        // Control interface
        .start(spi_start),
        .data_in(spi_data),
        .clk_div({4'b0000, clk_div_sw}),  // Extend to 8 bits
        .busy(spi_busy),
        
        // SPI interface
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi)
    );
    
    // Status outputs
    assign led_busy = spi_busy;
    assign led_mode = mode_sw;

endmodule
