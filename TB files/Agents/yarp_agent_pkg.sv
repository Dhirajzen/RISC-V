// YARP Agent Package - Collects all agent-related files
package yarp_agent_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  import yarp_pkg::*;
  import yarp_seq_pkg::*;
  
  // Include agent components
  `include "yarp_driver.sv"
  `include "yarp_monitor.sv"
  `include "yarp_sequencer.sv"  // Added sequencer file
  `include "yarp_agent.sv"
  
endpackage
