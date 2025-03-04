// YARP Sequence Package - Collects all sequence-related files
package yarp_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  import yarp_pkg::*;
  
  // Include sequence item definition
  `include "yarp_seq_item.sv"
  
  // Include sequence files
  `include "yarp_base_seq.sv"
  `include "yarp_sanity_seq.sv"
  `include "yarp_alu_seq.sv"
  `include "yarp_branch_seq.sv"
  `include "yarp_mem_seq.sv"
  `include "yarp_random_seq.sv"
  
endpackage
