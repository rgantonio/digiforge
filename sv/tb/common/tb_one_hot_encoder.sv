//--------------------------
// Testbench for the one hot encoder
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_one_hot_encoder;

  // Parameters
  parameter int unsigned OUTPUT_WIDTH = 16;
  parameter int unsigned INPUT_WIDTH  = $clog2(OUTPUT_WIDTH);

  // Inputs
  logic [ INPUT_WIDTH-1:0] value_i;
  logic                    en_out_i;

  // Outputs
  logic [OUTPUT_WIDTH-1:0] code_o;

  // Include some common tasks
  logic clk_i;
  `include "common_tasks.sv"

  // Instantiate the synchronizer flip-flop module
  one_hot_encoder #(
    .OUTPUT_WIDTH ( OUTPUT_WIDTH ),
    .INPUT_WIDTH  ( INPUT_WIDTH  )
  ) i_one_hot_encoder (
    .value_i      ( value_i      ),
    .en_out_i     ( en_out_i     ),
    .code_o       ( code_o       )
  );

  // Checking task
  task one_hot_checkder ();
    begin
      for (int i = 0; i < OUTPUT_WIDTH; i++) begin
          if (value_i == i) begin
            if (code_o[value_i] != 1) begin
              $error("ERROR! one-hot input: %h; one-hot output %b", value_i, code_o);
            end
          end else begin
            if (code_o[i] != 1'b0) begin
              $error("ERROR! one-hot input: %h; one-hot output %b", value_i, code_o);
            end
          end
      end
    end
  endtask

  // Test sequence
  initial begin
    // VCD dumping
    $dumpfile("tb_one_hot_encoder.vcd");
    $dumpvars(0, tb_one_hot_encoder);

    // Initialize inputs
    value_i  = 1'b0;
    en_out_i = 1'b0;
    time_delay(1ns);

    // Scan all possible outputs
    for (int i = 0; i < OUTPUT_WIDTH; i++) begin
      value_i  = i;
      en_out_i = 1'b1;
      time_delay(1ns);
      one_hot_checkder();
      $display("one-hot input: %h; one-hot output %b", value_i, code_o);
    end

    // Finish simulation
    #1; $finish;
  end

endmodule