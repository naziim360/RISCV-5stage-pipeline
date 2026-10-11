module reset_sync (
    input  logic clk,
    input  logic async_reset_n,   // raw, active-low on DE1
    output logic sync_reset       // synchronized, active-high reset
);
    logic meta;
    always_ff @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta       <= 1'b1;
            sync_reset <= 1'b1;
        end else begin
            meta       <= 1'b0;
            sync_reset <= meta;
        end
    end
endmodule