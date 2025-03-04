// YARP Test Package - Collects all test-related files
package yarp_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  import yarp_pkg::*;
  import yarp_seq_pkg::*;
  import yarp_agent_pkg::*;
  import yarp_env_pkg::*;
  
  // Include test files
  `include "yarp_base_test.sv"
  `include "yarp_sanity_test.sv"
  `include "yarp_alu_test.sv"
  `include "yarp_branch_test.sv"
  `include "yarp_mem_test.sv"
  `include "yarp_random_test.sv"
  
endpackage
