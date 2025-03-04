// YARP Sequencer - Controls sequence flow
class yarp_sequencer extends uvm_sequencer #(yarp_seq_item);
  // Registration with factory
  `uvm_component_utils(yarp_sequencer)
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  // Custom methods can be added here if needed for specialized sequencer behavior
  // For example:
  //   - Custom arbitration between competing sequences
  //   - Sequence prioritization
  //   - Response handling logic
  //   - Sequence coordination
  
endclass
