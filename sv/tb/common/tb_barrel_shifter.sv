// -------------------------------------------------------------------------
// File: Testbench for a Barrel Shifter
// Author: Danknight
// -------------------------------------------------------------------------

module tb_barrel_shifter #(
    parameter int DATA_W            = 32,
    parameter int SHIFT_W           = $clog2(DATA_W),
    parameter int NUM_TEST_CASES    = 10
);
    // -------------------------------------------------------------------------
    // Other parmaeters
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        OP_SLL = 3'b000, // Shift left logical
        OP_SRL = 3'b001, // Shift right logical
        OP_SRA = 3'b010, // Shift right arithmetic
        OP_ROL = 3'b011, // Rotate left
        OP_ROR = 3'b100  // Rotate right
    } op_sel_e;

    // -------------------------------------------------------------------------
    // Other signals
    // -------------------------------------------------------------------------
    logic [ DATA_W-1:0] data_i;
    logic [SHIFT_W-1:0] shift_amt_i;
    logic [        2:0] op_sel_i;
    logic [ DATA_W-1:0] data_o;
    logic [ DATA_W-1:0] expected_data;

    // -------------------------------------------------------------------------
    // Module instantiation
    // -------------------------------------------------------------------------
    barrel_shifter #(
        .DATA_W     (DATA_W     ),
        .SHIFT_W    (SHIFT_W    )
    ) i_barrel_shifter (
        .data_i     (data_i     ),
        .shift_amt_i(shift_amt_i),
        .op_sel_i   (op_sel_i   ),
        .data_o     (data_o     )
    );

    initial begin
        // Initialize all signals
        data_i      = '0;
        shift_amt_i = '0;
        op_sel_i    = '0;
        #1;

        // TC-01: SLL, shift_amt_i = 0 — passthrough
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = '0;
            op_sel_i    = OP_SLL;
            #1;
            assert(data_o == data_i) else $fatal("TC-01 failed: data_o != data_i");
        end
        $display("TC-01 passed: SLL, shift_amt_i = 0 — passthrough");

        // TC-02: SLL, shift_amt_i = DATA_W - 1 — only original LSB survives, at the MSB
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = DATA_W - 1;
            op_sel_i    = OP_SLL;
            #1;
            assert(data_o == {data_i[0], {(DATA_W-1){1'b0}}}) else $fatal("TC-02 failed: data_o != expected");
        end
        $display("TC-02 passed: SLL, shift_amt_i = DATA_W - 1 — only original LSB survives, at the MSB");

        // TC-03: SRL, shift_amt_i = DATA_W - 1 — only original MSB survives, at the LSB, zero-filled elsewhere
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = DATA_W - 1;
            op_sel_i    = OP_SRL;
            #1;
            assert(data_o == {{(DATA_W-1){1'b0}}, data_i[DATA_W-1]}) else $fatal("TC-03 failed: data_o != expected");
        end
        $display("TC-03 passed: SRL, shift_amt_i = DATA_W - 1 — only original MSB survives, at the LSB, zero-filled elsewhere");

        // TC-04: SRA with data_i[DATA_W-1] = 1 — verify sign fill, not zero fill
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom | (1 << (DATA_W-1)); // Ensure MSB is 1
            shift_amt_i = $urandom_range(1, DATA_W - 1);
            op_sel_i    = OP_SRA;
            #1;
            assert(data_o[DATA_W-1] == 1'b1) else $fatal("TC-04 failed: data_o[DATA_W-1] != 1");
        end
        $display("TC-04 passed: SRA with data_i[DATA_W-1] = 1 — verify sign fill, not zero fill");

        // TC-05: SRA with data_i[DATA_W-1] = 0 — verify SRA and SRL agree in this case
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom & ~((1 << (DATA_W-1))); // Ensure MSB is 0
            shift_amt_i = $urandom_range(1, DATA_W - 1);
            op_sel_i    = OP_SRA;
            #1;
            expected_data = data_i >> shift_amt_i;
            assert(data_o == expected_data) else $fatal("TC-05 failed: data_o != expected_data");
        end
        $display("TC-05 passed: SRA with data_i[DATA_W-1] = 0 — verify SRA and SRL agree in this case");

        // TC-06: ROL with shift_amt_i = 0 — passthrough, confirm the special-case doesn't corrupt output
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = '0;
            op_sel_i    = OP_ROL;
            #1;
            assert(data_o == data_i) else $fatal("TC-06 failed: data_o != data_i");
        end
        $display("TC-06 passed: ROL with shift_amt_i = 0 — passthrough, confirm the special-case doesn't corrupt output");

        // TC-07: ROL, arbitrary mid-range amount — confirm wrapped bits land correctly
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = $urandom_range(1, DATA_W - 1);
            op_sel_i    = OP_ROL;
            #1;
            expected_data = (data_i << shift_amt_i) | (data_i >> (DATA_W - shift_amt_i));
            assert(data_o == expected_data) else $fatal("TC-07 failed: data_o != expected_data");
        end
        $display("TC-07 passed: ROL, arbitrary mid-range amount — confirm wrapped bits land correctly");

        // TC-08: ROR, arbitrary mid-range amount — same, opposite direction
        for (int i = 0; i < NUM_TEST_CASES; i++) begin
            data_i      = $urandom;
            shift_amt_i = $urandom_range(1, DATA_W - 1);
            op_sel_i    = OP_ROR;
            #1;
            expected_data = (data_i >> shift_amt_i) | (data_i << (DATA_W - shift_amt_i));
            assert(data_o == expected_data) else $fatal("TC-08 failed: data_o != expected_data");
        end
        $display("TC-08 passed: ROR, arbitrary mid-range amount — same, opposite direction");

        $finish;
    end
endmodule