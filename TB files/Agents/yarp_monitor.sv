// YARP Monitor - Observes DUT behavior
class yarp_monitor extends uvm_monitor;
  // Registration with factory
  `uvm_component_utils(yarp_monitor)
  
  // Virtual interface handle
  virtual yarp_if vif;
  
  // Analysis ports for different transaction types
  uvm_analysis_port #(yarp_seq_item) instr_ap;   // Instruction fetch analysis port
  uvm_analysis_port #(yarp_seq_item) mem_rd_ap;  // Memory read analysis port
  uvm_analysis_port #(yarp_seq_item) mem_wr_ap;  // Memory write analysis port
  uvm_analysis_port #(yarp_seq_item) reg_wr_ap;  // Register write analysis port
  uvm_analysis_port #(yarp_seq_item) branch_ap;  // Branch outcome analysis port
  
  // Monitored register file (shadow copy)
  protected logic [31:0] reg_file[32];
  
  // Program counter tracking
  protected logic [31:0] prev_pc;
  protected logic [31:0] curr_pc;
  protected logic        is_branch_instr;
  protected logic        branch_taken;
  
  // Instruction tracking
  protected logic [31:0] curr_instr;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual yarp_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface must be set for monitor!")
    end
    
    // Create analysis ports
    instr_ap = new("instr_ap", this);
    mem_rd_ap = new("mem_rd_ap", this);
    mem_wr_ap = new("mem_wr_ap", this);
    reg_wr_ap = new("reg_wr_ap", this);
    branch_ap = new("branch_ap", this);
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  // Run phase
  virtual task run_phase(uvm_phase phase);
    // Initialize monitoring
    initialize();
    
    forever begin
      // Monitor a processor cycle
      monitor_cycle();
    end
  endtask
  
  // Initialize monitoring
  virtual task initialize();
    // Initialize register file
    for (int i = 0; i < 32; i++) begin
      reg_file[i] = 0;
    end
    
    // Initialize PC tracking
    prev_pc = 32'h0;
    curr_pc = 32'h0;
    is_branch_instr = 1'b0;
    branch_taken = 1'b0;
    
    // Initialize instruction tracking
    curr_instr = 32'h0;
    
    // Wait for reset to complete
    vif.wait_reset_done();
  endtask
  
  // Monitor a processor cycle
  virtual task monitor_cycle();
    // Wait for clock edge
    @(posedge vif.clk);
    
    // Update PC tracking
    prev_pc = curr_pc;
    curr_pc = vif.monitor_cb.pc;
    
    // Check if a branch was taken
    if (is_branch_instr) begin
      branch_taken = (curr_pc != prev_pc + 4);
      
      // Create branch outcome transaction
      yarp_seq_item branch_item = create_branch_item(branch_taken);
      
      // Send to analysis port
      branch_ap.write(branch_item);
      
      // Reset branch tracking
      is_branch_instr = 1'b0;
    end
    
    // Monitor instruction fetch
    if (vif.monitor_cb.instr_mem_req) begin
      monitor_instr_fetch();
    end
    
    // Monitor data memory access
    if (vif.monitor_cb.data_mem_req) begin
      if (vif.monitor_cb.data_mem_wr) begin
        monitor_data_write();
      end else begin
        monitor_data_read();
      end
    end
    
    // Monitor register file updates (done in simulation-specific manner)
    // This is a simplified approach, in a real testbench you might need to access
    // internal signals of the DUT
    monitor_reg_writes();
  endtask
  
  // Monitor instruction fetch
  virtual task monitor_instr_fetch();
    yarp_seq_item item;
    
    // Capture instruction and address
    logic [31:0] instr_addr = vif.monitor_cb.instr_mem_addr;
    
    // Wait for clock edge to get instruction data
    @(posedge vif.clk);
    logic [31:0] instr = vif.monitor_cb.instr_mem_rd_data;
    
    // Store current instruction for processing
    curr_instr = instr;
    
    // Create instruction fetch transaction
    item = yarp_seq_item::type_id::create("instr_item");
    item.tx_type = yarp_seq_item::INSTR_FETCH;
    item.address = instr_addr;
    item.decode_instruction(instr);
    
    // Check if this is a branch instruction
    is_branch_instr = item.is_b_type;
    
    // Send to analysis port
    instr_ap.write(item);
    
    `uvm_info(get_type_name(), $sformatf("Monitored instruction fetch: addr=0x%0h, instr=0x%0h", 
                                         instr_addr, instr), UVM_HIGH)
  endtask
  
  // Monitor data memory read
  virtual task monitor_data_read();
    yarp_seq_item item;
    
    // Capture address and byte enable
    logic [31:0] addr = vif.monitor_cb.data_mem_addr;
    logic [1:0] byte_en = vif.monitor_cb.data_mem_byte_en;
    
    // Wait for clock edge to get read data
    @(posedge vif.clk);
    logic [31:0] data = vif.monitor_cb.data_mem_rd_data;
    
    // Create data read transaction
    item = yarp_seq_item::type_id::create("mem_rd_item");
    item.tx_type = yarp_seq_item::DATA_READ;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    
    // Send to analysis port
    mem_rd_ap.write(item);
    
    `uvm_info(get_type_name(), $sformatf("Monitored data read: addr=0x%0h, data=0x%0h, byte_en=%0b", 
                                         addr, data, byte_en), UVM_HIGH)
  endtask
  
  // Monitor data memory write
  virtual task monitor_data_write();
    yarp_seq_item item;
    
    // Capture write information
    logic [31:0] addr = vif.monitor_cb.data_mem_addr;
    logic [1:0] byte_en = vif.monitor_cb.data_mem_byte_en;
    logic [31:0] data = vif.monitor_cb.data_mem_wr_data;
    
    // Create data write transaction
    item = yarp_seq_item::type_id::create("mem_wr_item");
    item.tx_type = yarp_seq_item::DATA_WRITE;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    
    // Send to analysis port
    mem_wr_ap.write(item);
    
    `uvm_info(get_type_name(), $sformatf("Monitored data write: addr=0x%0h, data=0x%0h, byte_en=%0b", 
                                         addr, data, byte_en), UVM_HIGH)
  endtask
  
  // Monitor register file writes
  // Note: This is a simplified approach - in a real testbench you would need access to internal signals
  virtual task monitor_reg_writes();
    // This method would normally access internal signals to monitor register writes
    // For this example, we'll use a more abstract approach
    
    // Decode the current instruction to determine if it writes to a register
    yarp_seq_item instr_item = yarp_seq_item::type_id::create("instr_decode");
    instr_item.decode_instruction(curr_instr);
    
    // Check if instruction writes to a register (most instructions do except branches and stores)
    if (!instr_item.is_b_type && !instr_item.is_s_type && instr_item.rd != 0) begin
      // In a real implementation, we would capture the actual register write value
      // from internal signals. For now, we'll create a placeholder transaction
      yarp_seq_item reg_item = yarp_seq_item::type_id::create("reg_wr_item");
      reg_item.tx_type = yarp_seq_item::REG_WRITE;
      reg_item.reg_addr = instr_item.rd;
      reg_item.data = 32'hDEADBEEF;  // Placeholder, would be actual value in real TB
      
      // Send to analysis port
      reg_wr_ap.write(reg_item);
      
      `uvm_info(get_type_name(), $sformatf("Monitored register write: reg=%0d, data=0x%0h", 
                                          instr_item.rd, reg_item.data), UVM_HIGH)
    end
  endtask
  
  // Create branch outcome transaction
  virtual function yarp_seq_item create_branch_item(logic taken);
    yarp_seq_item item = yarp_seq_item::type_id::create("branch_item");
    item.tx_type = yarp_seq_item::BRANCH_OUTCOME;
    item.branch_taken = taken;
    return item;
  endfunction
  
endclass
