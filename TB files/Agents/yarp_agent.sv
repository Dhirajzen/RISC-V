// YARP Agent - Encapsulates driver, monitor, and sequencer
class yarp_agent extends uvm_agent;
  // Registration with factory
  `uvm_component_utils(yarp_agent)
  
  // Components
  yarp_driver     driver;
  yarp_monitor    monitor;
  yarp_sequencer  sequencer;  // Now using our custom sequencer
  
  // Configuration
  protected bit is_active = 1;  // Active by default
  
  // Analysis ports for connecting to scoreboard/coverage
  uvm_analysis_port #(yarp_seq_item) instr_ap;   // Instruction fetch port
  uvm_analysis_port #(yarp_seq_item) mem_rd_ap;  // Memory read port
  uvm_analysis_port #(yarp_seq_item) mem_wr_ap;  // Memory write port
  uvm_analysis_port #(yarp_seq_item) reg_wr_ap;  // Register write port
  uvm_analysis_port #(yarp_seq_item) branch_ap;  // Branch outcome port
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    instr_ap = new("instr_ap", this);
    mem_rd_ap = new("mem_rd_ap", this);
    mem_wr_ap = new("mem_wr_ap", this);
    reg_wr_ap = new("reg_wr_ap", this);
    branch_ap = new("branch_ap", this);
    
    // Only create driver and sequencer if active
    if (is_active) begin
      driver = yarp_driver::type_id::create("driver", this);
      sequencer = yarp_sequencer::type_id::create("sequencer", this);
    end
    
    // Always create monitor
    monitor = yarp_monitor::type_id::create("monitor", this);
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor to analysis ports
    monitor.instr_ap.connect(instr_ap);
    monitor.mem_rd_ap.connect(mem_rd_ap);
    monitor.mem_wr_ap.connect(mem_wr_ap);
    monitor.reg_wr_ap.connect(reg_wr_ap);
    monitor.branch_ap.connect(branch_ap);
    
    // Connect driver and sequencer if active
    if (is_active) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
  
  // Set active/passive mode
  function void set_active(bit is_active);
    this.is_active = is_active;
  endfunction
  
endclass
