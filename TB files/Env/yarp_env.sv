// YARP Environment - Encapsulates all verification components
class yarp_env extends uvm_env;
  // Registration with factory
  `uvm_component_utils(yarp_env)
  
  // Components
  yarp_agent          agent;
  yarp_scoreboard     scoreboard;
  yarp_coverage       coverage;
  yarp_reference_model ref_model;
  
  // Configuration
  protected bit enable_scoreboard = 1;  // Enable scoreboard by default
  protected bit enable_coverage = 1;    // Enable coverage by default
  protected bit enable_ref_model = 1;   // Enable reference model by default
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create agent
    agent = yarp_agent::type_id::create("agent", this);
    
    // Create scoreboard if enabled
    if (enable_scoreboard) begin
      scoreboard = yarp_scoreboard::type_id::create("scoreboard", this);
    end
    
    // Create coverage if enabled
    if (enable_coverage) begin
      coverage = yarp_coverage::type_id::create("coverage", this);
    end
    
    // Create reference model if enabled
    if (enable_ref_model) begin
      ref_model = yarp_reference_model::type_id::create("ref_model", this);
    end
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect agent to scoreboard if enabled
    if (enable_scoreboard) begin
      agent.instr_ap.connect(scoreboard.instr_fifo);
      agent.mem_rd_ap.connect(scoreboard.mem_rd_fifo);
      agent.mem_wr_ap.connect(scoreboard.mem_wr_fifo);
      agent.reg_wr_ap.connect(scoreboard.reg_wr_fifo);
      agent.branch_ap.connect(scoreboard.branch_fifo);
    end
    
    // Connect agent to coverage if enabled
    if (enable_coverage) begin
      agent.instr_ap.connect(coverage.item_collected_export);
      agent.mem_rd_ap.connect(coverage.item_collected_export);
      agent.mem_wr_ap.connect(coverage.item_collected_export);
      agent.reg_wr_ap.connect(coverage.item_collected_export);
      agent.branch_ap.connect(coverage.item_collected_export);
    end
    
    // Connect agent to reference model if enabled
    if (enable_ref_model) begin
      agent.instr_ap.connect(ref_model.instr_imp);
      
      // Connect reference model to scoreboard for comparison
      if (enable_scoreboard) begin
        ref_model.mem_read_port.connect(scoreboard.ref_mem_rd_fifo);
        ref_model.mem_write_port.connect(scoreboard.ref_mem_wr_fifo);
        ref_model.reg_write_port.connect(scoreboard.ref_reg_wr_fifo);
        ref_model.branch_port.connect(scoreboard.ref_branch_fifo);
      end
    end
  endfunction
  
  // Configuration methods
  function void set_scoreboard_enabled(bit enabled);
    enable_scoreboard = enabled;
  endfunction
  
  function void set_coverage_enabled(bit enabled);
    enable_coverage = enabled;
  endfunction
  
  function void set_ref_model_enabled(bit enabled);
    enable_ref_model = enabled;
  endfunction
  
  // Reset all components
  virtual function void reset();
    if (enable_scoreboard) begin
      scoreboard.reset();
    end
    
    if (enable_ref_model) begin
      ref_model.reset();
    end
  endfunction
  
endclass
