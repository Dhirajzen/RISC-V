// YARP Reference Model - High-level model of RISC-V processor for verification
class yarp_reference_model extends uvm_component;
  // Registration with factory
  `uvm_component_utils(yarp_reference_model)
  
  // Analysis ports for receiving transactions
  uvm_analysis_imp #(yarp_seq_item, yarp_reference_model) instr_imp;  // Instruction fetch port
  
  // Analysis ports for sending expected transactions
  uvm_analysis_port #(yarp_seq_item) mem_read_port;   // Expected memory reads
  uvm_analysis_port #(yarp_seq_item) mem_write_port;  // Expected memory writes
  uvm_analysis_port #(yarp_seq_item) reg_write_port;  // Expected register writes
  uvm_analysis_port #(yarp_seq_item) branch_port;     // Expected branch outcomes
  
  // Processor state
  logic [31:0] registers[32];     // Register file
  logic [31:0] memory[logic [31:0]];    // Memory model
  logic [31:0] pc;                // Program counter
  logic [31:0] next_pc;           // Next program counter
  
  // Current instruction being processed
  yarp_seq_item current_instr;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    instr_imp = new("instr_imp", this);
    mem_read_port = new("mem_read_port", this);
    mem_write_port = new("mem_write_port", this);
    reg_write_port = new("reg_write_port", this);
    branch_port = new("branch_port", this);
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  // Reset the model
  virtual function void reset();
    // Clear register file (except x0 which is always 0)
    foreach (registers[i]) registers[i] = 0;
    
    // Clear memory model
    memory.delete();
    
    // Reset PC
    pc = 32'h1000; // Default reset value
    next_pc = pc + 4;
  endfunction
  
  // Write implementation for instruction fetch
  virtual function void write(yarp_seq_item item);
    // Store current instruction
    current_instr = item;
    
    // Update PC
    pc = item.address;
    next_pc = pc + 4;
    
    // Process instruction
    process_instruction(item);
  endfunction
  
  // Process an instruction and update processor state
  virtual function void process_instruction(yarp_seq_item item);
    logic [31:0] result;
    logic branch_taken = 1'b0;
    
    // Determine instruction type and execute
    if (item.is_r_type) begin
      // R-type instruction execution
      result = execute_r_type(item);
      
      // Update register file (if rd != 0)
      if (item.rd != 0) begin
        registers[item.rd] = result;
        
        // Create register write transaction
        yarp_seq_item reg_item = create_reg_write(item.rd, result);
        reg_write_port.write(reg_item);
      end
    end
    else if (item.is_i_type) begin
      // I-type instruction execution
      if (item.opcode == 7'h03) begin
        // Load instruction
        execute_load(item);
      end
      else if (item.opcode == 7'h13) begin
        // I-type ALU instruction
        result = execute_i_type_alu(item);
        
        // Update register file (if rd != 0)
        if (item.rd != 0) begin
          registers[item.rd] = result;
          
          // Create register write transaction
          yarp_seq_item reg_item = create_reg_write(item.rd, result);
          reg_write_port.write(reg_item);
        end
      end
      else if (item.opcode == 7'h67) begin
        // JALR instruction
        logic [31:0] target = (registers[item.rs1] + item.imm) & ~32'h1;
        
        // Save return address
        if (item.rd != 0) begin
          registers[item.rd] = next_pc;
          
          // Create register write transaction
          yarp_seq_item reg_item = create_reg_write(item.rd, next_pc);
          reg_write_port.write(reg_item);
        end
        
        // Update next PC
        next_pc = target;
      end
    end
    else if (item.is_s_type) begin
      // S-type instruction execution (store)
      execute_store(item);
    end
    else if (item.is_b_type) begin
      // B-type instruction execution (branch)
      branch_taken = execute_branch(item);
      
      // Create branch outcome transaction
      yarp_seq_item branch_item = create_branch_outcome(branch_taken);
      branch_port.write(branch_item);
      
      // Update next PC if branch taken
      if (branch_taken) begin
        next_pc = pc + item.imm;
      end
    end
    else if (item.is_u_type) begin
      // U-type instruction execution
      if (item.opcode == 7'h37) begin
        // LUI instruction
        result = item.imm;
      end
      else if (item.opcode == 7'h17) begin
        // AUIPC instruction
        result = pc + item.imm;
      end
      
      // Update register file (if rd != 0)
      if (item.rd != 0) begin
        registers[item.rd] = result;
        
        // Create register write transaction
        yarp_seq_item reg_item = create_reg_write(item.rd, result);
        reg_write_port.write(reg_item);
      end
    end
    else if (item.is_j_type) begin
      // J-type instruction execution (JAL)
      // Save return address
      if (item.rd != 0) begin
        registers[item.rd] = next_pc;
        
        // Create register write transaction
        yarp_seq_item reg_item = create_reg_write(item.rd, next_pc);
        reg_write_port.write(reg_item);
      end
      
      // Update next PC
      next_pc = pc + item.imm;
    end
  endfunction
  
  // Execute R-type instruction
  virtual function logic [31:0] execute_r_type(yarp_seq_item item);
    logic [31:0] result;
    logic [31:0] rs1_val = registers[item.rs1];
    logic [31:0] rs2_val = registers[item.rs2];
    
    // Combine funct7[5] and funct3 to determine operation
    logic [3:0] funct = {item.funct7[5], item.funct3};
    
    case (funct)
      4'h0: result = rs1_val + rs2_val;                          // ADD
      4'h8: result = rs1_val - rs2_val;                          // SUB
      4'h1: result = rs1_val << rs2_val[4:0];                    // SLL
      4'h2: result = ($signed(rs1_val) < $signed(rs2_val)) ? 1 : 0; // SLT
      4'h3: result = (rs1_val < rs2_val) ? 1 : 0;                // SLTU
      4'h4: result = rs1_val ^ rs2_val;                          // XOR
      4'h5: result = rs1_val >> rs2_val[4:0];                    // SRL
      4'hd: result = $signed(rs1_val) >>> rs2_val[4:0];          // SRA
      4'h6: result = rs1_val | rs2_val;                          // OR
      4'h7: result = rs1_val & rs2_val;                          // AND
      default: result = 0;
    endcase
    
    return result;
  endfunction
  
  // Execute I-type ALU instruction
  virtual function logic [31:0] execute_i_type_alu(yarp_seq_item item);
    logic [31:0] result;
    logic [31:0] rs1_val = registers[item.rs1];
    logic [31:0] imm_val = item.imm;
    
    case (item.funct3)
      3'b000: result = rs1_val + imm_val;                     // ADDI
      3'b010: result = ($signed(rs1_val) < $signed(imm_val)) ? 1 : 0; // SLTI
      3'b011: result = (rs1_val < imm_val) ? 1 : 0;           // SLTIU
      3'b100: result = rs1_val ^ imm_val;                     // XORI
      3'b110: result = rs1_val | imm_val;                     // ORI
      3'b111: result = rs1_val & imm_val;                     // ANDI
      3'b001: result = rs1_val << imm_val[4:0];               // SLLI
      3'b101: begin
        if (item.funct7[5]) result = $signed(rs1_val) >>> imm_val[4:0]; // SRAI
        else result = rs1_val >> imm_val[4:0];                // SRLI
      end
      default: result = 0;
    endcase
    
    return result;
  endfunction
  
  // Execute load instruction
  virtual function void execute_load(yarp_seq_item item);
    logic [31:0] addr = registers[item.rs1] + item.imm;
    logic [31:0] data;
    logic [31:0] result;
    
    // Align address based on access size
    logic [31:0] aligned_addr = {addr[31:2], 2'b00};
    logic [1:0] byte_offset = addr[1:0];
    
    // Check if memory location exists
    if (memory.exists(aligned_addr)) begin
      data = memory[aligned_addr];
    end else begin
      data = 0;  // Default value for uninitialized memory
    end
    
    // Create memory read transaction
    yarp_seq_item mem_item = create_data_read(addr, data, get_byte_enable(item.funct3));
    mem_read_port.write(mem_item);
    
    // Extract data based on access type
    case (item.funct3)
      3'b000: begin // LB
        logic [7:0] byte_val;
        byte_val = (data >> (byte_offset * 8)) & 8'hFF;
        result = {{24{byte_val[7]}}, byte_val};  // Sign extend
      end
      
      3'b001: begin // LH
        logic [15:0] half_val;
        half_val = (data >> ((byte_offset & 2'b10) * 8)) & 16'hFFFF;
        result = {{16{half_val[15]}}, half_val};  // Sign extend
      end
      
      3'b010: begin // LW
        result = data;
      end
      
      3'b100: begin // LBU
        logic [7:0] byte_val;
        byte_val = (data >> (byte_offset * 8)) & 8'hFF;
        result = {24'b0, byte_val};  // Zero extend
      end
      
      3'b101: begin // LHU
        logic [15:0] half_val;
        half_val = (data >> ((byte_offset & 2'b10) * 8)) & 16'hFFFF;
        result = {16'b0, half_val};  // Zero extend
      end
      
      default: result = 0;
    endcase
    
    // Update register file (if rd != 0)
    if (item.rd != 0) begin
      registers[item.rd] = result;
      
      // Create register write transaction
      yarp_seq_item reg_item = create_reg_write(item.rd, result);
      reg_write_port.write(reg_item);
    end
  endfunction
  
  // Execute store instruction
  virtual function void execute_store(yarp_seq_item item);
    logic [31:0] addr = registers[item.rs1] + item.imm;
    logic [31:0] data = registers[item.rs2];
    logic [31:0] mem_val;
    
    // Align address based on access size
    logic [31:0] aligned_addr = {addr[31:2], 2'b00};
    logic [1:0] byte_offset = addr[1:0];
    
    // Get current memory value (if exists)
    if (memory.exists(aligned_addr)) begin
      mem_val = memory[aligned_addr];
    end else begin
      mem_val = 0;  // Default value for uninitialized memory
    end
    
    // Update memory based on access type
    case (item.funct3)
      3'b000: begin // SB
        logic [31:0] mask = 32'h000000FF << (byte_offset * 8);
        logic [31:0] data_shifted = (data & 32'h000000FF) << (byte_offset * 8);
        memory[aligned_addr] = (mem_val & ~mask) | data_shifted;
      end
      
      3'b001: begin // SH
        logic [31:0] mask = 32'h0000FFFF << ((byte_offset & 2'b10) * 8);
        logic [31:0] data_shifted = (data & 32'h0000FFFF) << ((byte_offset & 2'b10) * 8);
        memory[aligned_addr] = (mem_val & ~mask) | data_shifted;
      end
      
      3'b010: begin // SW
        memory[aligned_addr] = data;
      end
      
      default: ;  // Do nothing for invalid funct3
    endcase
    
    // Create memory write transaction
    yarp_seq_item mem_item = create_data_write(addr, data, get_byte_enable(item.funct3));
    mem_write_port.write(mem_item);
  endfunction
  
  // Execute branch instruction
  virtual function logic execute_branch(yarp_seq_item item);
    logic [31:0] rs1_val = registers[item.rs1];
    logic [31:0] rs2_val = registers[item.rs2];
    logic branch_taken;
    
    case (item.funct3)
      3'b000: branch_taken = (rs1_val == rs2_val);                          // BEQ
      3'b001: branch_taken = (rs1_val != rs2_val);                          // BNE
      3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val));         // BLT
      3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));        // BGE
      3'b110: branch_taken = (rs1_val < rs2_val);                           // BLTU
      3'b111: branch_taken = (rs1_val >= rs2_val);                          // BGEU
      default: branch_taken = 1'b0;
    endcase
    
    return branch_taken;
  endfunction
  
  // Helper function to create data read transaction
  virtual function yarp_seq_item create_data_read(logic [31:0] addr, logic [31:0] data, logic [1:0] byte_en);
    yarp_seq_item item = yarp_seq_item::type_id::create("mem_rd_item");
    item.tx_type = yarp_seq_item::DATA_READ;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    return item;
  endfunction
  
  // Helper function to create data write transaction
  virtual function yarp_seq_item create_data_write(logic [31:0] addr, logic [31:0] data, logic [1:0] byte_en);
    yarp_seq_item item = yarp_seq_item::type_id::create("mem_wr_item");
    item.tx_type = yarp_seq_item::DATA_WRITE;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    return item;
  endfunction
  
  // Helper function to create register write transaction
  virtual function yarp_seq_item create_reg_write(logic [4:0] reg_addr, logic [31:0] data);
    yarp_seq_item item = yarp_seq_item::type_id::create("reg_wr_item");
    item.tx_type = yarp_seq_item::REG_WRITE;
    item.reg_addr = reg_addr;
    item.data = data;
    return item;
  endfunction
  
  // Helper function to create branch outcome transaction
  virtual function yarp_seq_item create_branch_outcome(logic taken);
    yarp_seq_item item = yarp_seq_item::type_id::create("branch_item");
    item.tx_type = yarp_seq_item::BRANCH_OUTCOME;
    item.branch_taken = taken;
    return item;
  endfunction
  
  // Helper function to convert funct3 to byte enable
  virtual function logic [1:0] get_byte_enable(logic [2:0] funct3);
    case (funct3)
      3'b000, 3'b100: return 2'b00;  // Byte (LB, LBU, SB)
      3'b001, 3'b101: return 2'b01;  // Half-word (LH, LHU, SH)
      3'b010:         return 2'b11;  // Word (LW, SW)
      default:        return 2'b11;  // Default to word
    endcase
  endfunction
  
endclass
