// YARP Branch Test - Focused on branch operations
class yarp_branch_test extends yarp_base_test;
  // Registration with factory
  `uvm_component_utils(yarp_branch_test)
  
  // Constructor
  function new(string name = "yarp_branch_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Test-specific sequence
  virtual task run_test_sequence(uvm_phase phase);
    yarp_branch_seq seq;
    
    // Create and start the branch sequence
    seq = yarp_branch_seq::type_id::create("seq");
    
    `uvm_info(get_type_name(), "Starting branch test sequence", UVM_LOW)
    
    if (!seq.randomize()) begin
      `uvm_error(get_type_name(), "Failed to randomize branch sequence")
    end
    
    seq.test_all_branch_types = 1;     // Test all branch conditions
    seq.test_branch_edge_cases = 1;    // Test boundary conditions
    
    seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Branch test sequence completed", UVM_LOW)
  endtask
  
endclass
