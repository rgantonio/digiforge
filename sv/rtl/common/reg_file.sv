// -------------------------------------------------------------------------
// File: Register File with Multiple Read/Write Ports
// Author: Danknight
// -------------------------------------------------------------------------
module reg_file #(
    parameter int DATA_W       = 32,
    parameter int ADDR_W       = 5,
    parameter int NUM_RD_PORTS = 2,
    parameter int NUM_WR_PORTS = 1
)(
    input  logic                                       clk_i,
    input  logic                                       rst_ni,
    // Write ports
    input  logic [NUM_WR_PORTS-1:0]                    wr_en_i,
    input  logic [NUM_WR_PORTS-1:0][ADDR_W-1:0]        wr_addr_i,
    input  logic [NUM_WR_PORTS-1:0][DATA_W-1:0]        wr_data_i,
    // Read ports
    input  logic [NUM_RD_PORTS-1:0][ADDR_W-1:0]        rd_addr_i,
    output logic [NUM_RD_PORTS-1:0][DATA_W-1:0]        rd_data_o
);

    localparam int DEPTH = 1 << ADDR_W;

    // Register array — index 0 is never written
    logic [DATA_W-1:0] mem [DEPTH];

    // -------------------------------------------------------------------------
    // Write logic (synchronous, active-low reset)
    // Lower-priority ports written first so higher-index wins on address collision
    // -------------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            for (int i = 0; i < DEPTH; i++)
                mem[i] <= '0;
        end else begin
            for (int i = 0; i < NUM_WR_PORTS; i++) begin
                if (wr_en_i[i] && (wr_addr_i[i] != '0))
                    mem[wr_addr_i[i]] <= wr_data_i[i];
            end
        end
    end

    // -------------------------------------------------------------------------
    // Read logic (combinational, with WBR forwarding)
    // For each read port j (0..NUM_RD_PORTS-1):
    //   1. Default: rd_data_o[j] = mem[rd_addr_i[j]]
    //   2. Override with WBR: for each write port i where wr_en_i[i] is high
    //      and wr_addr_i[i] == rd_addr_i[j], forward wr_data_i[i].
    //      Highest-index write port wins on collision.
    //   3. Guard: if rd_addr_i[j] == '0, always return '0.
    // -------------------------------------------------------------------------
    always_comb begin
        for (int j = 0; j < NUM_RD_PORTS; j++) begin
            if (rd_addr_i[j] == '0) begin
                rd_data_o[j] = '0;
            end else begin
                rd_data_o[j] = mem[rd_addr_i[j]];
                for (int i = 0; i < NUM_WR_PORTS; i++) begin
                    if (wr_en_i[i] && (wr_addr_i[i] == rd_addr_i[j])) begin
                        rd_data_o[j] = wr_data_i[i];
                    end
                end
            end
        end
    end

endmodule
