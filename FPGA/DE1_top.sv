module DE1_top (
    input  logic       CLOCK_50,
    input  logic [3:0] KEY,
    input  logic [9:0] SW,

    output logic [9:0] LEDR,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3
);

    // reset
    logic sync_reset;

    reset_sync u_reset_sync (
        .clk           (CLOCK_50),
        .async_reset_n (KEY[0]),
        .sync_reset    (sync_reset)
    );

	 
    logic debug_wb;//keeps the whole CPU from being optimized away 

    datapath_pipeline u_datapath_pipeline (
        .clk       (CLOCK_50),
        .reset     (sync_reset),
        .debug_out (debug_wb)
    );


    assign LEDR[0]   = debug_wb;
    assign LEDR[9:1] = 9'b0;

    assign HEX0 = 7'h7F;
    assign HEX1 = 7'h7F;
    assign HEX2 = 7'h7F;
    assign HEX3 = 7'h7F;

endmodule