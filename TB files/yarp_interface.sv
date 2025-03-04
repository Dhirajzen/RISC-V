// YARP Interface - Connects the testbench to the DUT
interface yarp_if(input logic clk, input logic reset_n);
  
  // Instruction memory interface signals
  logic          instr_mem_req;
  logic [31:0]   instr_mem_addr;
  logic [31:0]   instr_mem_rd_data;
  
  // Data memory interface signals
  logic          data_mem_req;
  logic [31:0]   data_mem_addr;
  logic [1:0]    data_mem_byte_en;
  logic          data_mem_wr;
  logic [31:0]   data_mem_wr_data;
  logic [31:0]   data_mem_rd_data;
  
  // UVM specific signals (for monitoring internal states)
  logic [31:0]   pc;  // Program counter value
  
  // Clocking blocks for synchronization
  
  // Driver clocking block - used by driver to drive signals
  clocking driver_cb @(posedge clk);
    output instr_mem_rd_data;
    output data_mem_rd_data;
    input  instr_mem_req;
    input  instr_mem_addr;
    input  data_mem_req;
    input  data_mem_addr;
    input  data_mem_byte_en;
    input  data_mem_wr;
    input  data_mem_wr_data;
  endclocking
  
  // Monitor clocking block - used by monitor to sample signals
  clocking monitor_cb @(posedge clk);
    input instr_mem_req;
    input instr_mem_addr;
    input instr_mem_rd_data;
    input data_mem_req;
    input data_mem_addr;
    input data_mem_byte_en;
    input data_mem_wr;
    input data_mem_wr_data;
    input data_mem_rd_data;
    input pc;
  endclocking
  
  // Modports for connecting to driver and monitor
  modport DRIVER (clocking driver_cb, input clk, input reset_n);
  modport MONITOR (clocking monitor_cb, input clk, input reset_n);
  
  // Tasks and functions for the interface
  
  // Wait for reset to complete
  task wait_reset_done();
    @(posedge reset_n);
    @(posedge clk);
  endtask
  
  // Wait for number of clock cycles
  task wait_cycles(int n);
    repeat(n) @(posedge clk);
  endtask
  
  // Signal access methods for easier use in testbench
  function logic is_mem_write();
    return (data_mem_req && data_mem_wr);
  endfunction
  
  function logic is_mem_read();
    return (data_mem_req && !data_mem_wr);
  endfunction
  
  function logic is_instr_fetch();
    return instr_mem_req;
  endfunction
  
endinterface
