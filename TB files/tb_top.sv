// YARP Testbench Top - Instantiates DUT and UVM testbench
`include "uvm_macros.svh"

module tb_top;
  import uvm_pkg::*;
  import yarp_pkg::*;
  import yarp_uvm_pkg::*;
  
  // Clock and reset signals
  logic clk;
  logic reset_n;
  
  // Interface instance
  yarp_if vif(clk, reset_n);
  
  // DUT instance
  yarp_top #(
    .RESET_PC(32'h1000)
  ) dut (
    .clk                    (clk),
    .reset_n                (reset_n),
    .instr_mem_req_o        (vif.instr_mem_req),
    .instr_mem_addr_o       (vif.instr_mem_addr),
    .instr_mem_rd_data_i    (vif.instr_mem_rd_data),
    .data_mem_req_o         (vif.data_mem_req),
    .data_mem_addr_o        (vif.data_mem_addr),
    .data_mem_byte_en_o     (vif.data_mem_byte_en),
    .data_mem_wr_o          (vif.data_mem_wr),
    .data_mem_wr_data_o     (vif.data_mem_wr_data),
    .data_mem_rd_data_i     (vif.data_mem_rd_data)
  );
  
  // Access to internal program counter for monitoring
  assign vif.pc = dut.pc_q;
  
  // Generate clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz clock
  end
  
  // Reset generation
  initial begin
    reset_n = 0;
    repeat(5) @(posedge clk);
    reset_n = 1;
  end
  
  // Start UVM phases
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual yarp_if)::set(null, "uvm_test_top", "vif", vif);
    
    // Run the test
    run_test();
  end
  
  // Timeout watchdog
  initial begin
    #1000000;  // 1ms timeout
    `uvm_fatal("TIMEOUT", "Simulation timed out")
  end
  
  // Dump waveforms
  initial begin
    $dumpfile("yarp_tb.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule
