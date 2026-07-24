// -------------------------------------------------------------------------
// File: Barrel Shifter with Operational Changes
// Author: Danknight
// -------------------------------------------------------------------------

module barrel_shifter #(
    parameter int DATA_W = 32,
    parameter int SHIFT_W = $clog2(DATA_W)
)(
    input  logic [ DATA_W-1:0] data_i,
    input  logic [SHIFT_W-1:0] shift_amt_i,
    input  logic [2:0]         op_sel_i,
    output logic [DATA_W-1:0]  data_o
);

    // Parameter
    localparam int STAGES = SHIFT_W;

    typedef enum logic [2:0] {
        OP_SLL = 3'b000, // Shift left logical
        OP_SRL = 3'b001, // Shift right logical
        OP_SRA = 3'b010, // Shift right arithmetic
        OP_ROL = 3'b011, // Rotate left
        OP_ROR = 3'b100  // Rotate right
    } op_sel_e;

    // Stages
    logic [DATA_W-1:0] stage [STAGES+1];

    // Initial stage
    assign stage[0] = data_i;

    // Shift stages
    genvar k;
    generate
        for (k = 0; k < STAGES; k++) begin : g_stage
            logic [DATA_W-1:0] shifted_value;

            always_comb begin
                unique case (op_sel_i)
                    OP_SLL:  shifted_value = stage[k] << (1 << k);
                    OP_SRL:  shifted_value = stage[k] >> (1 << k);
                    OP_SRA:  shifted_value = $signed(stage[k]) >>> (1 << k);
                    OP_ROL:  shifted_value = ({stage[k], stage[k]} >> (DATA_W - (1 << k)));
                    OP_ROR:  shifted_value = ({stage[k], stage[k]} >> (1 << k));
                    default: shifted_value = stage[k];
                endcase
            end

            assign stage[k+1] = (shift_amt_i[k]) ? shifted_value : stage[k];
        end
    endgenerate

    assign data_o = (op_sel_i > 3'b100) ? '0 : stage[STAGES];

endmodule