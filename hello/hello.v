// Simple Hello World Verilog Module
module hello (
    input wire clk,
    input wire rst_n,
    output reg [3:0] counter
);

    // Counter that increments on each clock cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'b0000;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
