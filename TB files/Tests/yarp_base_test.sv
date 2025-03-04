// YARP Base Test - Common test functionality
class yarp_base_test extends uvm_test;
  // Registration with factory
  `uvm_component_utils(yarp_base_test)
  
  // Environment
  yarp_env env;
  
  // Virtual interface handle
  virtual yarp_if vif;
  
  // Constructor
  function new(string name = "yarp_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create environment
    env = yarp_env::type_id::create("env", this);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual yarp_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface must be set for test!")
    end
    
    // Configure virtual interface to UVM components
    uvm_config_db#(virtual yarp_if)::set(this, "env.agent.*", "vif", vif);
  endfunction
  
  // End of elaboration phase - print topology
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Printing the test topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction
  
  // Run phase - execute test
  virtual task run_phase(uvm_phase phase);
    // Raise objection to keep test from completing
    phase.raise_objection(this, "Starting test");
    
    // Wait for reset to complete
    vif.wait_reset_done();
    
    // Reset the environment components
    env.reset();
    
    // Run test-specific sequence (implemented by child classes)
    run_test_sequence(phase);
    
    // Allow some time for processing to complete
    vif.wait_cycles(20);
    
    // Drop objection to allow test to complete
    phase.drop_objection(this, "Finishing test");
  endtask
  
  // Test-specific sequence to be implemented by child classes
  virtual task run_test_sequence(uvm_phase phase);
    // Default implementation - do nothing
    `uvm_info(get_type_name(), "Base test has no test sequence - override in child class", UVM_LOW)
  endtask
  
endclass
