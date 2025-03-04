// YARP Random Test - Random instruction sequence
class yarp_random_test extends yarp_base_test;
  // Registration with factory
  `uvm_component_utils(yarp_random_test)
  
  // Configuration parameters
  rand int unsigned instruction_count;
  rand int unsigned seed;
  
  // Constraints
  constraint reasonable_count {
    instruction_count inside {[50:200]};
  }
  
  // Constructor
  function new(string name = "yarp_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase - randomize test parameters
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!this.randomize()) begin
      `uvm_error(get_type_name(), "Failed to randomize test parameters")
    end
    
    `uvm_info(get_type_name(), $sformatf("Random test configured: instr_count=%0d, seed=%0d", 
                                        instruction_count, seed), UVM_LOW)
  endfunction
  
  // Test-specific sequence
  virtual task run_test_sequence(uvm_phase phase);
    yarp_random_seq seq;
    
    // Create and start the random sequence
    seq = yarp_random_seq::type_id::create("seq");
    
    `uvm_info(get_type_name(), "Starting random test sequence", UVM_LOW)
    
    // Set sequence parameters
    seq.instruction_count = this.instruction_count;
    
    if (!seq.randomize() with { 
        instruction_count == local::instruction_count;
    }) begin
      `uvm_error(get_type_name(), "Failed to randomize random sequence")
    end
    
    seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Random test sequence completed", UVM_LOW)
  endtask
  
endclass
