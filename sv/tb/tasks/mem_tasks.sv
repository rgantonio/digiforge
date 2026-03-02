//--------------------------
// Library of memory tasks for the TB
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

// Memory unit tasks
task mem_unit_write(
  input logic [ADDR_WIDTH-1:0] addr,
  input logic [DATA_WIDTH-1:0] data
);
  begin
    req_i     = 1;
    w_en_i    = 1;
    addr_i    = addr;
    w_data_i  = data;
    b_en_i    = {ADDR_BYTE_WIDTH{1'b1}};
    clk_unit_delay();
    req_i     = 0;
    w_en_i    = 0;
  end
endtask

task mem_unit_read(
  input logic LATENCY,
  input logic [ADDR_WIDTH-1:0] addr
);
  begin
    req_i     = 1;
    w_en_i    = 0;
    addr_i    = addr;
    b_en_i    = {ADDR_BYTE_WIDTH{1'b1}};
    if(LATENCY > 0) begin
      clk_unit_delay();
      req_i     = 0;
      w_en_i    = 0;
    end else begin
      // Small delay to propagate logic
      #1;
    end
  end
endtask

task mem_unit_check(
  input logic [ADDR_WIDTH-1:0] addr,
  input logic [DATA_WIDTH-1:0] data
);
  begin
    if (r_data_o !== data) begin
      $error("Memory read error at address %h: expected %h, got %h", addr, data, r_data_o);
    end else begin
      $display("Memory read success at address %h: got %h", addr, r_data_o);
    end
  end
endtask
