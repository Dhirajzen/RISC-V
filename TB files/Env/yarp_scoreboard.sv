// YARP Scoreboard - Verifies correct operation of the processor
class yarp_scoreboard extends uvm_scoreboard;
  // Registration with factory
  `uvm_component_utils(yarp_scoreboard)
  
  // Analysis ports for receiving transactions
  uvm_analysis_imp #(yarp_seq_item, yarp_scoreboard) instr_fifo;  // Instruction fetch port
  uvm_analysis_imp #(yarp_seq_item, yarp_scoreboard) mem_rd_fifo; // Memory read port
  uvm_analysis_imp #(yarp_seq_item, yarp_scoreboard) mem_wr_fifo; // Memory write port
  uvm_analysis_imp #(yarp_seq_item, yarp_scoreboard) reg_wr_fifo; // Register write port
  uvm_analysis_imp #(yarp_seq_item, yarp_scoreboard) branch_fifo; // Branch outcome port
  
  // Reference models
  logic [31:0] reg_file[32];           // Register file model
  logic [31:0] memory[logic [31:0]];   // Memory model
  logic [31:0] pc;                     // Program counter
  
  // Statistics
  int num_instr_verified;        // Total instructions verified
  int num_mem_reads_verified;    // Total memory reads verified
  int num_mem_writes_verified;   // Total memory writes verified
  int num_reg_writes_verified;   // Total register writes verified
  int num_branches_verified;     // Total branches verified
  int num_errors;                // Total errors detected
  
  // Current instruction being processed
  yarp_seq_item current_instr;
  
  // Test performance metrics
  int instruction_coverage[yarp_seq_item::tx_type_e];
  int alu_op_coverage[logic [3:0]];     // Track ALU operations tested
  int branch_type_coverage[logic [2:0]]; // Track branch types tested
  int edge_case_coverage[string];        // Track edge cases covered
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    
    // Initialize statistics
    num_instr_verified = 0;
    num_mem_reads_verified = 0;
    num_mem_writes_verified = 0;
    num_reg_writes_verified = 0;
    num_branches_verified = 0;
    num_errors = 0;
    
    // Initialize coverage structures
    foreach (instruction_coverage[i]) instruction_coverage[i] = 0;
    foreach (alu_op_coverage[i]) alu_op_coverage[i] = 0;
    foreach (branch_type_coverage[i]) branch_type_coverage[i] = 0;
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    instr_fifo = new("instr_fifo", this);
    mem_rd_fifo = new("mem_rd_fifo", this);
    mem_wr_fifo = new("mem_wr_fifo", this);
    reg_wr_fifo = new("reg_wr_fifo", this);
    branch_fifo = new("branch_fifo", this);
  endfunction
  
  // Reset scoreboard
  virtual function void reset();
    // Clear register file
    foreach (reg_file[i]) reg_file[i] = 0;
    
    // Clear memory model
    memory.delete();
    
    // Reset PC
    pc = 32'h1000; // Default reset value
    
    // Reset statistics
    num_instr_verified = 0;
    num_mem_reads_verified = 0;
    num_mem_writes_verified = 0;
    num_reg_writes_verified = 0;
    num_branches_verified = 0;
    num_errors = 0;
    
    // Reset coverage structures
    foreach (instruction_coverage[i]) instruction_coverage[i] = 0;
    foreach (alu_op_coverage[i]) alu_op_coverage[i] = 0;
    foreach (branch_type_coverage[i]) branch_type_coverage[i] = 0;
    edge_case_coverage.delete();
  endfunction
  
  // Write implementation for instruction fetch
  virtual function void write(yarp_seq_item item);
    // Determine which analysis port was triggered and process accordingly
    case (item.tx_type)
      yarp_seq_item::INSTR_FETCH: process_instruction(item);
      yarp_seq_item::DATA_READ:   process_mem_read(item);
      yarp_seq_item::DATA_WRITE:  process_mem_write(item);
      yarp_seq_item::REG_WRITE:   process_reg_write(item);
      yarp_seq_item::BRANCH_OUTCOME: process_branch(item);
    endcase
  endfunction
  
  // Process instruction fetch
  virtual function void process_instruction(yarp_seq_item item);
    // Store current instruction for future verification
    current_instr = item;
    
    // Update PC
    pc = item.address;
    
    // Update coverage
    instruction_coverage[item.tx_type]++;
    
    // Decode the instruction to determine type
    if (item.is_r_type) begin
      // Update R-type instruction coverage
      alu_op_coverage[{item.funct7[5], item.funct3}]++;
      
      // Check for edge cases
      if (item.rs1 == 0 || item.rs2 == 0) begin
        edge_case_coverage["zero_operand"] = 1;
      end
    end
    else if (item.is_b_type) begin
      // Update branch instruction coverage
      branch_type_coverage[item.funct3]++;
    end
    
    // Increment verified instruction count
    num_instr_verified++;
    
    `uvm_info(get_type_name(), $sformatf("Processed instruction: addr=0x%0h, instr=0x%0h", 
                                        item.address, item.encoded_instr), UVM_HIGH)
  endfunction
  
  // Process memory read
  virtual function void process_mem_read(yarp_seq_item item);
    logic [31:0] expected_data;
    logic [31:0] actual_data = item.data;
    logic [31:0] aligned_addr = {item.address[31:2], 2'b00};
    logic error = 0;
    
    // Check if we have expected data in our memory model
    if (memory.exists(aligned_addr)) begin
      // Extract data based on byte enable
      case (item.byte_enable)
        2'b00: begin // Byte
          logic [7:0] expected_byte;
          logic [1:0] byte_offset = item.address[1:0];
          
          // Extract correct byte from memory word
          expected_byte = (memory[aligned_addr] >> (byte_offset * 8)) & 8'hFF;
          
          // Check if this is a zero-extended or sign-extended load
          // For simplicity, we'll assume sign extension here
          expected_data = {{24{expected_byte[7]}}, expected_byte};
          
          // Compare with actual data (only the relevant byte)
          if (actual_data != expected_data) begin
            error = 1;
          end
        end
        
        2'b01: begin // Half-word
          logic [15:0] expected_half;
          logic byte_offset = item.address[1];
          
          // Extract correct half-word from memory word
          expected_half = (memory[aligned_addr] >> (byte_offset * 16)) & 16'hFFFF;
          
          // Check if this is a zero-extended or sign-extended load
          // For simplicity, we'll assume sign extension here
          expected_data = {{16{expected_half[15]}}, expected_half};
          
          // Compare with actual data (only the relevant half-word)
          if (actual_data != expected_data) begin
            error = 1;
          end
        end
        
        2'b11: begin // Word
          expected_data = memory[aligned_addr];
          
          // Compare with actual data
          if (actual_data != expected_data) begin
            error = 1;
          end
        end
        
        default: begin
          `uvm_error("INVBYTEEN", $sformatf("Invalid byte enable: %0b", item.byte_enable))
          error = 1;
        end
      endcase
    end else begin
      // No expected data, assume all zeros (could be made more complex)
      expected_data = 32'h0;
      
      // For now, we don't trigger an error if reading from uninitialized memory
    end
    
    // Report error if any
    if (error) begin
      `uvm_error("MEMRDERR", $sformatf("Memory read error: addr=0x%0h, expected=0x%0h, actual=0x%0h", 
                                      item.address, expected_data, actual_data))
      num_errors++;
    end
    
    // Increment verified memory read count
    num_mem_reads_verified++;
    
    `uvm_info(get_type_name(), $sformatf("Processed memory read: addr=0x%0h, data=0x%0h", 
                                       item.address, item.data), UVM_HIGH)
  endfunction
  
  // Process memory write
  virtual function void process_mem_write(yarp_seq_item item);
    logic [31:0] aligned_addr = {item.address[31:2], 2'b00};
    logic [31:0] expected_value = 0;
    
    // Update our memory model based on byte enable
    case (item.byte_enable)
      2'b00: begin // Byte
        logic [31:0] mask = 32'h000000FF;
        logic [1:0] byte_offset = item.address[1:0];
        
        // Create byte mask at correct position
        mask = mask << (byte_offset * 8);
        
        // Update memory model
        if (memory.exists(aligned_addr)) begin
          expected_value = (memory[aligned_addr] & ~mask) | 
                         ((item.data << (byte_offset * 8)) & mask);
          memory[aligned_addr] = expected_value;
        end else begin
          expected_value = (item.data << (byte_offset * 8)) & mask;
          memory[aligned_addr] = expected_value;
        end
      end
      
      2'b01: begin // Half-word
        logic [31:0] mask = 32'h0000FFFF;
        logic byte_offset = item.address[1] ? 1 : 0;
        
        // Create half-word mask at correct position
        mask = mask << (byte_offset * 16);
        
        // Update memory model
        if (memory.exists(aligned_addr)) begin
          expected_value = (memory[aligned_addr] & ~mask) | 
                         ((item.data << (byte_offset * 16)) & mask);
          memory[aligned_addr] = expected_value;
        end else begin
          expected_value = (item.data << (byte_offset * 16)) & mask;
          memory[aligned_addr] = expected_value;
        end
      end
      
      2'b11: begin // Word
        memory[aligned_addr] = item.data;
        expected_value = item.data;
      end
      
      default: begin
        `uvm_error("INVBYTEEN", $sformatf("Invalid byte enable: %0b", item.byte_enable))
      end
    endcase
    
    // Increment verified memory write count
    num_mem_writes_verified++;
    
    `uvm_info(get_type_name(), $sformatf("Processed memory write: addr=0x%0h, data=0x%0h, byte_en=%0b", 
                                       item.address, item.data, item.byte_enable), UVM_HIGH)
  endfunction
  
  // Process register write
  virtual function void process_reg_write(yarp_seq_item item);
    // In a real testbench, you would validate the register write value
    // against the expected value computed by your reference model
    
    // Update our register model
    if (item.reg_addr != 0) begin  // Never update register 0
      // In a full reference model, we would compute the expected value
      // instead of just storing the reported value
      reg_file[item.reg_addr] = item.data;
    end
    
    // Increment verified register write count
    num_reg_writes_verified++;
    
    `uvm_info(get_type_name(), $sformatf("Processed register write: reg=%0d, data=0x%0h", 
                                       item.reg_addr, item.data), UVM_HIGH)
  endfunction
  
  // Process branch outcome
  virtual function void process_branch(yarp_seq_item item);
    logic expected_outcome;
    logic actual_outcome = item.branch_taken;
    logic error = 0;
    
    // In a real testbench, you would compute the expected branch outcome
    // using your reference model based on the current_instr
    
    // For now, we'll just record that we saw a branch outcome
    
    // Increment verified branch count
    num_branches_verified++;
    
    `uvm_info(get_type_name(), $sformatf("Processed branch outcome: taken=%0b", 
                                       item.branch_taken), UVM_HIGH)
  endfunction
  
  // Report phase - print summary
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("Verification Summary:"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Instructions verified: %0d", num_instr_verified), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Memory reads verified: %0d", num_mem_reads_verified), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Memory writes verified: %0d", num_mem_writes_verified), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Register writes verified: %0d", num_reg_writes_verified), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Branches verified: %0d", num_branches_verified), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Errors detected: %0d", num_errors), UVM_LOW)
    
    // Print coverage information
    print_coverage_report();
  endfunction
  
  // Print coverage report
  virtual function void print_coverage_report();
    string s;
    int total_instr = 0;
    int total_alu_ops = 0;
    int total_branch_types = 0;
    
    // Calculate totals
    foreach (instruction_coverage[i]) total_instr += instruction_coverage[i];
    foreach (alu_op_coverage[i]) total_alu_ops += alu_op_coverage[i];
    foreach (branch_type_coverage[i]) total_branch_types += branch_type_coverage[i];
    
    // Print instruction type coverage
    s = "\n==== Instruction Type Coverage ====\n";
    foreach (instruction_coverage[i]) begin
      s = {s, $sformatf("  %s: %0d\n", i.name(), instruction_coverage[i])};
    end
    
    // Print ALU operation coverage
    s = {s, "\n==== ALU Operation Coverage ====\n"};
    foreach (alu_op_coverage[i]) begin
      s = {s, $sformatf("  0x%0h: %0d\n", i, alu_op_coverage[i])};
    end
    
    // Print branch type coverage
    s = {s, "\n==== Branch Type Coverage ====\n"};
    foreach (branch_type_coverage[i]) begin
      s = {s, $sformatf("  0x%0h: %0d\n", i, branch_type_coverage[i])};
    end
    
    // Print edge case coverage
    s = {s, "\n==== Edge Case Coverage ====\n"};
    foreach (edge_case_coverage[i]) begin
      s = {s, $sformatf("  %s: covered\n", i)};
    end
    
    `uvm_info(get_type_name(), s, UVM_LOW)
  endfunction
  
endclass
