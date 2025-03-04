// YARP ALU Test - Focused on ALU operations
class yarp_alu_test extends yarp_base_test;
  // Registration with factory
  `uvm_component_utils(yarp_alu_test)
  
  // Constructor
  function new(string name = "yarp_alu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Test-specific sequence
  virtual task run_test_sequence(uvm_phase phase);
    yarp_alu_seq seq;
    
    // Create and start the ALU sequence
    seq = yarp_alu_seq::type_id::create("seq");
    
    `uvm_info(get_type_name(), "Starting ALU test sequence", UVM_LOW)
    
    if (!seq.randomize()) begin
      `uvm_error(get_type_name(), "Failed to randomize ALU sequence")
    end
    
    seq.test_all_ops = 1;       // Test all ALU operations
    seq.test_edge_cases = 1;    // Test edge cases
    
    seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "ALU test sequence completed", UVM_LOW)
  endtask
  
endclass
