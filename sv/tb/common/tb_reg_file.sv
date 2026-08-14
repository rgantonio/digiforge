// -------------------------------------------------------------------------
// File: Testbench for a Register File with Multiple Read/Write Ports
// Author: Danknight
// -------------------------------------------------------------------------

module tb_reg_file #(
    parameter int DATA_W       = 32,
    parameter int ADDR_W       = 5,
    parameter int NUM_RD_PORTS = 2,
    parameter int NUM_WR_PORTS = 1
);

    // -------------------------------------------------------------------------
    // Clock and Reset
    // -------------------------------------------------------------------------
    logic clk_i;
    logic rst_ni;

    // -------------------------------------------------------------------------
    // Other signals
    // -------------------------------------------------------------------------

    // Write ports
    logic [NUM_WR_PORTS-1:0]                    wr_en_i;
    logic [NUM_WR_PORTS-1:0][ADDR_W-1:0]        wr_addr_i;
    logic [NUM_WR_PORTS-1:0][DATA_W-1:0]        wr_data_i;

    // Read ports
    logic [NUM_RD_PORTS-1:0][ADDR_W-1:0]        rd_addr_i;
    logic [NUM_RD_PORTS-1:0][DATA_W-1:0]        rd_data_o;

    // -------------------------------------------------------------------------
    // Module instantiation
    // -------------------------------------------------------------------------
    reg_file #(
        .DATA_W         (DATA_W         ),
        .ADDR_W         (ADDR_W         ),
        .NUM_RD_PORTS   (NUM_RD_PORTS   ),
        .NUM_WR_PORTS   (NUM_WR_PORTS   )
    ) i_reg_file (
        .clk_i          (clk_i          ),
        .rst_ni         (rst_ni         ),
        .wr_en_i        (wr_en_i        ),
        .wr_addr_i      (wr_addr_i      ),
        .wr_data_i      (wr_data_i      ),
        .rd_addr_i      (rd_addr_i      ),
        .rd_data_o      (rd_data_o      )
    );

    // -------------------------------------------------------------------------
    // Always block for clock generation
    // -------------------------------------------------------------------------
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz clock
    end

    // -------------------------------------------------------------------------
    // Test and Stimuli
    // -------------------------------------------------------------------------
    initial begin
        // Initialize all signals
        rst_ni      = 1'b0;
        wr_en_i     = '0;
        wr_addr_i   = '0;
        wr_data_i   = '0;
        rd_addr_i   = '0;

        // Release reset after 2 clk periods
        @(posedge clk_i);
        @(posedge clk_i);
        rst_ni = 1;

        // TC-01: Reset all registers to 0
        // After a reset check if all registers are 0
        for (int i = 0; i < (1 << ADDR_W); i++) begin
            rd_addr_i[0] = i;
            @(posedge clk_i);

            assert(rd_data_o[0] == '0)
            else $fatal("TC-01: Register %0d is not reset to 0", i);
        end
        $display("TC-01: All registers are reset to 0");

        // TC-02: Write to a register and read it back
        for (int i = 1; i < (1 << ADDR_W); i++) begin
            wr_en_i[0] = 1;
            wr_addr_i[0] = i;
            wr_data_i[0] = $urandom_range(0, (1 << DATA_W) - 1);
            @(posedge clk_i);
            wr_en_i[0] = 0;

            rd_addr_i[0] = i;
            @(posedge clk_i);

            assert(rd_data_o[0] == wr_data_i[0])
            else $fatal("TC-02: Register %0d read back value is incorrect", i);
        end
        $display("TC-02: All registers written and read back correctly");

        // TC-03: Ignore writes to register 0 and always read 0
        for (int i = 0; i < 10; i++) begin
            wr_en_i[0] = 1;
            wr_addr_i[0] = 0;
            wr_data_i[0] = $urandom_range(0, (1 << DATA_W) - 1);
            @(posedge clk_i);

            wr_en_i[0] = 0;
            rd_addr_i[0] = 0;
            @(posedge clk_i);

            assert(rd_data_o[0] == '0)
            else $fatal("TC-03: Register 0 read back value is not 0");
        end
        $display("TC-03: Register 0 is always read as 0");

        // TC-04: Forward write data to read port in same cycle (WBR)
        for (int i = 1; i < (1 << ADDR_W); i++) begin
            wr_en_i[0] = 1;
            wr_addr_i[0] = i;
            wr_data_i[0] = $urandom_range(0, (1 << DATA_W) - 1);
            rd_addr_i[0] = i;
            @(posedge clk_i);

            assert(rd_data_o[0] == wr_data_i[0])
            else $fatal("TC-04: Register %0d WBR forwarding failed", i);
        end
        $display("TC-04: WBR forwarding works correctly");

        $finish;
    end
endmodule
