// YARP Driver - Drives transactions to the DUT
class yarp_driver extends uvm_driver #(yarp_seq_item);
  // Registration with factory
  `uvm_component_utils(yarp_driver)
  
  // Virtual interface handle
  virtual yarp_if vif;
  
  // Memory models
  protected logic [31:0] instr_mem[logic [31:0]];
  protected logic [31:0] data_mem[logic [31:0]];
  
  // Track current PC value
  protected logic [31:0] current_pc;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual yarp_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface must be set for driver!")
    end
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  // Run phase
  virtual task run_phase(uvm_phase phase);
    // Initialize memories and interface
    initialize();
    
    forever begin
      // Get next transaction
      seq_item_port.get_next_item(req);
      
      // Process the transaction
      drive_transaction(req);
      
      // Signal completion
      seq_item_port.item_done();
    end
  endtask
  
  // Initialize memories and interface
  virtual task initialize();
    // Initialize memories
    instr_mem.delete();
    data_mem.delete();
    
    // Default instruction memory with NOPs
    for (int i = 0; i < 32'h1000; i += 4) begin
      instr_mem[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
    end
    
    // Initialize data memory with zeros
    for (int i = 0; i < 32'h1000; i += 4) begin
      data_mem[i] = 32'h0;
    end
    
    // Reset interface signals
    vif.instr_mem_rd_data = 32'h0;
    vif.data_mem_rd_data = 32'h0;
    
    // Wait for reset to complete
    vif.wait_reset_done();
    
    // Initialize current PC tracking
    current_pc = 32'h1000;  // Default reset PC
  endtask
  
  // Drive a transaction to the DUT
  virtual task drive_transaction(yarp_seq_item item);
    // Process based on transaction type
    case (item.tx_type)
      yarp_seq_item::INSTR_FETCH: begin
        // Store instruction in memory for future reference
        instr_mem[item.address] = item.encoded_instr;
        
        // Drive instruction fetch
        drive_instr_fetch(item);
      end
      
      yarp_seq_item::DATA_READ: begin
        // Drive data memory read
        drive_data_read(item);
      end
      
      yarp_seq_item::DATA_WRITE: begin
        // Update data memory with write
        drive_data_write(item);
      end
      
      yarp_seq_item::REG_WRITE, yarp_seq_item::BRANCH_OUTCOME: begin
        // These are monitoring transactions, not driven
        // Just advance time
        vif.wait_cycles(1);
      end
      
      default: begin
        `uvm_error("INVTX", $sformatf("Invalid transaction type: %s", item.tx_type.name()))
      end
    endcase
  endtask
  
  // Drive instruction fetch
  virtual task drive_instr_fetch(yarp_seq_item item);
    // Wait for instruction fetch request
    @(posedge vif.clk);
    
    // Check that instruction fetch is happening and address matches expected
    if (vif.instr_mem_req && vif.instr_mem_addr == item.address) begin
      // Return the instruction data
      vif.instr_mem_rd_data = item.encoded_instr;
      
      // Update current PC tracking
      current_pc = item.address;
      
      `uvm_info(get_type_name(), $sformatf("Driving instruction: addr=0x%0h, instr=0x%0h", 
                                           item.address, item.encoded_instr), UVM_HIGH)
    end else begin
      // Address mismatch - handle error
      `uvm_error("PCMISMATCH", $sformatf("PC mismatch: expected=0x%0h, actual=0x%0h", 
                                        item.address, vif.instr_mem_addr))
      
      // Still drive the instruction to avoid deadlock
      vif.instr_mem_rd_data = item.encoded_instr;
    end
    
    // Wait for next clock edge
    @(posedge vif.clk);
  endtask
  
  // Drive data memory read
  virtual task drive_data_read(yarp_seq_item item);
    // Wait for data read request
    wait(vif.data_mem_req && !vif.data_mem_wr);
    
    // Store data at address for reference
    data_mem[item.address] = item.data;
    
    // Check address matches
    if (vif.data_mem_addr == item.address) begin
      // Return the data
      vif.data_mem_rd_data = item.data;
      
      `uvm_info(get_type_name(), $sformatf("Driving data read: addr=0x%0h, data=0x%0h, byte_en=%0b", 
                                          item.address, item.data, vif.data_mem_byte_en), UVM_HIGH)
    end else begin
      // Address mismatch - handle error
      `uvm_error("ADDRMISMATCH", $sformatf("Address mismatch: expected=0x%0h, actual=0x%0h", 
                                          item.address, vif.data_mem_addr))
      
      // Still drive the data to avoid deadlock
      vif.data_mem_rd_data = item.data;
    end
    
    // Wait for next clock edge
    @(posedge vif.clk);
  endtask
  
  // Drive data memory write
  virtual task drive_data_write(yarp_seq_item item);
    // Wait for data write request
    wait(vif.data_mem_req && vif.data_mem_wr);
    
    // Update data memory with write data based on byte enable
    case (vif.data_mem_byte_en)
      2'b00: begin // Byte
        logic [31:0] mask = 32'h000000FF;
        logic [31:0] mask_addr = {vif.data_mem_addr[31:2], 2'b00};
        logic [1:0] byte_offset = vif.data_mem_addr[1:0];
        
        // Create byte mask at correct position
        mask = mask << (byte_offset * 8);
        
        // Update memory
        if (data_mem.exists(mask_addr)) begin
          data_mem[mask_addr] = (data_mem[mask_addr] & ~mask) | 
                               ((vif.data_mem_wr_data << (byte_offset * 8)) & mask);
        end else begin
          data_mem[mask_addr] = (vif.data_mem_wr_data << (byte_offset * 8)) & mask;
        end
      end
      
      2'b01: begin // Half-word
        logic [31:0] mask = 32'h0000FFFF;
        logic [31:0] mask_addr = {vif.data_mem_addr[31:2], 2'b00};
        logic byte_offset = vif.data_mem_addr[1] ? 1 : 0;
        
        // Create half-word mask at correct position
        mask = mask << (byte_offset * 16);
        
        // Update memory
        if (data_mem.exists(mask_addr)) begin
          data_mem[mask_addr] = (data_mem[mask_addr] & ~mask) | 
                               ((vif.data_mem_wr_data << (byte_offset * 16)) & mask);
        end else begin
          data_mem[mask_addr] = (vif.data_mem_wr_data << (byte_offset * 16)) & mask;
        end
      end
      
      2'b11: begin // Word
        data_mem[vif.data_mem_addr] = vif.data_mem_wr_data;
      end
    endcase
    
    // Log the write operation
    `uvm_info(get_type_name(), $sformatf("Data memory write: addr=0x%0h, data=0x%0h, byte_en=%0b", 
                                         vif.data_mem_addr, vif.data_mem_wr_data, vif.data_mem_byte_en), UVM_HIGH)
    
    // Wait for next clock edge
    @(posedge vif.clk);
  endtask
  
endclass
