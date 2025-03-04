// YARP Random Sequence - Generates random instruction sequences
class yarp_random_seq extends yarp_base_seq;
  // Registration with factory
  `uvm_object_utils(yarp_random_seq)
  
  // Variables to control random generation
  rand int unsigned instruction_count;      // Number of instructions to generate
  rand int unsigned branch_percentage;      // Percentage of branch instructions (0-100)
  rand int unsigned mem_access_percentage;  // Percentage of memory access instructions (0-100)
  rand int unsigned alu_percentage;         // Percentage of ALU instructions (0-100)
  int unsigned jump_percentage;             // Percentage of jump instructions (derived from others)
  
  // Maximum memory address (to avoid boundary violations)
  logic [31:0] max_mem_addr = 32'h3FFC;
  
  // Label support for branches and jumps
  protected int label_counter;
  protected logic [31:0] labels[int];  // Maps label IDs to addresses
  
  // Register tracking for data dependencies
  protected logic [31:0] reg_values[32];
  protected bit reg_valid[32];
  
  // Constraints
  constraint reasonable_counts {
    instruction_count inside {[20:200]};
    branch_percentage inside {[5:30]};
    mem_access_percentage inside {[10:40]};
    alu_percentage inside {[30:80]};
    branch_percentage + mem_access_percentage + alu_percentage <= 100;
  }
  
  // Constructor
  function new(string name = "yarp_random_seq");
    super.new(name);
    label_counter = 0;
  endfunction
  
  // Pre-body function
  virtual task pre_body();
    super.pre_body();
    
    // Calculate jump percentage
    jump_percentage = 100 - (branch_percentage + mem_access_percentage + alu_percentage);
    
    // Initialize register tracking
    foreach (reg_valid[i]) reg_valid[i] = 0;
    // x0 is always 0
    reg_values[0] = 0;
    reg_valid[0] = 1;
    
    `uvm_info(get_type_name(), $sformatf("Generating random sequence with %0d instructions", instruction_count), UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("Instruction mix: ALU=%0d%%, Memory=%0d%%, Branch=%0d%%, Jump=%0d%%", 
                                        alu_percentage, mem_access_percentage, branch_percentage, jump_percentage), UVM_MEDIUM)
  endtask
  
  // Body task - generates the sequence
  virtual task body();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = 32'h1000;  // Default reset PC
    int instr_type;
    
    // Initialize some registers with known values for testing
    initialize_registers(pc);
    pc += 20;  // Skip 5 instructions (4 bytes each)
    
    // Generate random instruction sequence
    for (int i = 0; i < instruction_count; i++) begin
      // Determine instruction type based on percentages
      instr_type = $urandom_range(1, 100);
      
      if (instr_type <= alu_percentage) begin
        // Generate ALU instruction
        instr = generate_random_alu_instr(pc);
      end
      else if (instr_type <= (alu_percentage + mem_access_percentage)) begin
        // Generate memory access instruction
        instr = generate_random_mem_instr(pc);
      end
      else if (instr_type <= (alu_percentage + mem_access_percentage + branch_percentage)) begin
        // Generate branch instruction
        instr = generate_random_branch_instr(pc, i, instruction_count);
      end
      else begin
        // Generate jump instruction
        instr = generate_random_jump_instr(pc);
      end
      
      // Store instruction in memory
      instr_mem[pc] = instr;
      
      // Create instruction fetch transaction
      item = create_instr_fetch(pc, instr);
      start_item(item);
      finish_item(item);
      
      // Update PC
      pc += 4;
      
      // Process memory transactions if needed
      if (item.is_s_type) begin
        // For store instructions, create the memory write transaction
        process_store_transaction(item);
      end
      else if (item.is_i_type && item.opcode == 7'h03) begin
        // For load instructions, create the memory read transaction
        process_load_transaction(item);
      end
    }
    
    // Add a final ADDI x0, x0, 0 (NOP) to mark the end
    instr = gen_i_type_alu(3'b000, 5'd0, 5'd0, 12'h0);  // addi x0, x0, 0
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
  endtask
  
  // Helper to initialize registers with useful test values
  virtual task initialize_registers(logic [31:0] pc);
    yarp_seq_item item;
    
    // Set x1 to 0x12345678
    instr_mem[pc] = gen_u_type_instr(1'b0, 5'd1, 20'h12345);  // lui x1, 0x12345
    instr_mem[pc+4] = gen_i_type_alu(3'b000, 5'd1, 5'd1, 12'h678);  // addi x1, x1, 0x678
    
    // Set x2 to 0x87654321
    instr_mem[pc+8] = gen_u_type_instr(1'b0, 5'd2, 20'h87654);  // lui x2, 0x87654
    instr_mem[pc+12] = gen_i_type_alu(3'b000, 5'd2, 5'd2, 12'h321);  // addi x2, x2, 0x321
    
    // Set x3 to a small positive value (10)
    instr_mem[pc+16] = gen_i_type_alu(3'b000, 5'd3, 5'd0, 12'h0A);  // addi x3, x0, 10
    
    // Fetch all initialization instructions
    for (int i = 0; i < 5; i++) begin
      item = create_instr_fetch(pc + (i*4), instr_mem[pc + (i*4)]);
      start_item(item);
      finish_item(item);
    end
    
    // Update register tracking
    reg_values[1] = 32'h12345678;
    reg_valid[1] = 1;
    reg_values[2] = 32'h87654321;
    reg_valid[2] = 1;
    reg_values[3] = 32'h0000000A;
    reg_valid[3] = 1;
  endtask
  
  // Generate a random ALU instruction
  virtual function logic [31:0] generate_random_alu_instr(logic [31:0] pc);
    logic [31:0] instr;
    int instr_subtype = $urandom_range(0, 2);  // 0=R-type, 1=I-type, 2=U-type
    
    case (instr_subtype)
      0: begin  // R-type
        logic [4:0] rd, rs1, rs2;
        logic [2:0] funct3;
        logic funct7_5;
        
        // Random registers
        rd = $urandom_range(1, 31);  // Avoid x0
        rs1 = choose_valid_reg();
        rs2 = choose_valid_reg();
        
        // Random function
        funct3 = $urandom_range(0, 7);
        funct7_5 = $urandom_range(0, 1);
        
        // Make sure ADD/SUB, SRL/SRA are properly distinguished
        if (funct3 == 3'b000 || funct3 == 3'b101) begin
          funct7_5 = $urandom_range(0, 1);  // Allow both options
        end else begin
          funct7_5 = 1'b0;  // Others only valid with funct7_5 = 0
        end
        
        // Generate instruction
        instr = gen_r_type_with_funct(funct3, funct7_5, rd, rs1, rs2);
        
        // Update register tracking
        update_reg_after_alu_op(rd, rs1, rs2, funct3, funct7_5);
      end
      
      1: begin  // I-type
        logic [4:0] rd, rs1;
        logic [2:0] funct3;
        logic [11:0] imm;
        
        // Random registers
        rd = $urandom_range(1, 31);  // Avoid x0
        rs1 = choose_valid_reg();
        
        // Random function and immediate
        funct3 = $urandom_range(0, 7);
        imm = $urandom & 12'hFFF;
        
        // Special case for shift instructions
        if (funct3 == 3'b001 || funct3 == 3'b101) begin
          imm = imm & 12'h01F;  // Only lower 5 bits used for shift amount
          
          // For SRAI (right shift arithmetic), set the special bit
          if (funct3 == 3'b101 && $urandom_range(0, 1)) begin
            imm = imm | 12'h400;  // Set bit 10 to indicate SRAI
          end
        end
        
        // Generate instruction
        instr = gen_i_type_alu(funct3, rd, rs1, imm);
        
        // Update register tracking
        update_reg_after_i_alu_op(rd, rs1, funct3, imm);
      end
      
      2: begin  // U-type
        logic [4:0] rd;
        logic [19:0] imm;
        logic u_type;  // 0=LUI, 1=AUIPC
        
        // Random registers and immediate
        rd = $urandom_range(1, 31);  // Avoid x0
        imm = $urandom;
        u_type = $urandom_range(0, 1);
        
        // Generate instruction
        instr = gen_u_type_instr(u_type, rd, imm);
        
        // Update register tracking
        if (u_type == 0) begin
          // LUI: rd = imm << 12
          reg_values[rd] = {imm, 12'h0};
        end else begin
          // AUIPC: rd = pc + (imm << 12)
          reg_values[rd] = pc + {imm, 12'h0};
        end
        reg_valid[rd] = 1;
      end
    endcase
    
    return instr;
  endfunction
  
  // Generate a random memory access instruction
  virtual function logic [31:0] generate_random_mem_instr(logic [31:0] pc);
    logic [31:0] instr;
    int instr_subtype = $urandom_range(0, 1);  // 0=load, 1=store
    logic [1:0] size = $urandom_range(0, 2);   // 0=byte, 1=half-word, 2=word
    logic [1:0] byte_en;
    
    // Convert size to byte_enable format
    case (size)
      0: byte_en = 2'b00;  // byte
      1: byte_en = 2'b01;  // half-word
      2: byte_en = 2'b11;  // word
    endcase
    
    if (instr_subtype == 0) begin  // Load
      logic [4:0] rd, rs1;
      logic [11:0] offset;
      logic zero_extend = $urandom_range(0, 1);  // 0=sign extend, 1=zero extend
      
      // Random registers and offset
      rd = $urandom_range(1, 31);  // Avoid x0
      rs1 = choose_valid_reg();
      offset = $urandom & 12'hFFF;
      
      // For byte/half-word, decide between zero and sign extension
      if (size < 2 && zero_extend) begin
        // Use zero-extended load instructions (LBU, LHU)
        instr = gen_load_instr_zero_ext(byte_en, rd, rs1, offset);
      end else begin
        // Use sign-extended load instructions (LB, LH, LW)
        instr = gen_load_instr(byte_en, rd, rs1, offset);
      end
      
      // Update register tracking - mark as valid but value unknown
      reg_valid[rd] = 1;
      // We could calculate the exact value if we tracked memory, but for now just mark as valid
    end
    else begin  // Store
      logic [4:0] rs1, rs2;
      logic [11:0] offset;
      
      // Random registers and offset
      rs1 = choose_valid_reg();
      rs2 = choose_valid_reg();
      offset = $urandom & 12'hFFF;
      
      // Generate store instruction
      instr = gen_store_instr(byte_en, rs2, rs1, offset);
      
      // No register state update needed for store
    end
    
    return instr;
  endfunction
  
  // Generate a random branch instruction
  virtual function logic [31:0] generate_random_branch_instr(logic [31:0] pc, int instr_index, int total_instrs);
    logic [31:0] instr;
    logic [4:0] rs1, rs2;
    logic [2:0] funct3;
    logic [12:0] offset;
    
    // Random registers
    rs1 = choose_valid_reg();
    rs2 = choose_valid_reg();
    
    // Random branch type
    funct3 = $urandom_range(0, 7);
    if (funct3 == 3'b010 || funct3 == 3'b011) begin
      // These values are invalid for B-type, reassign
      funct3 = $urandom_range(0, 1);  // BEQ or BNE
    end
    
    // Determine branch target
    if ($urandom_range(0, 100) < 70) begin
      // 70% of branches are forward
      int forward_distance = $urandom_range(1, (total_instrs - instr_index) / 2) * 4;
      // Make sure we don't go beyond the end of the program
      forward_distance = (forward_distance + pc > max_mem_addr) ? 
                         (max_mem_addr - pc - 4) : forward_distance;
      // Ensure multiple of 2 for offset
      offset = (forward_distance / 2) & 12'hFFF;
    end
    else begin
      // 30% of branches are backward
      int backward_distance = $urandom_range(1, instr_index / 2) * 4;
      // Ensure multiple of 2 for offset
      offset = -((backward_distance / 2) & 12'hFFF);
    end
    
    // Generate branch instruction
    instr = gen_branch_instruction(funct3, rs1, rs2, offset);
    
    return instr;
  endfunction
  
  // Generate a random jump instruction
  virtual function logic [31:0] generate_random_jump_instr(logic [31:0] pc);
    logic [31:0] instr;
    int jump_type = $urandom_range(0, 1);  // 0=JAL, 1=JALR
    
    if (jump_type == 0) begin  // JAL
      logic [4:0] rd;
      logic [20:0] offset;
      
      // Usually save return address in ra (x1), sometimes in another register
      rd = ($urandom_range(0, 100) < 80) ? 5'd1 : $urandom_range(1, 31);
      
      // Random jump offset (must be divisible by 2)
      offset = ($urandom & 20'hFFFFF) & ~1;
      
      // 50% chance of negative offset (jump backward)
      if ($urandom_range(0, 1)) begin
        offset = -offset;
      end
      
      // Ensure we don't jump too far
      if (pc + offset > max_mem_addr || pc + offset < 32'h1000) begin
        offset = 32'h1000 - pc;  // Jump back to start
      end
      
      // Generate JAL instruction
      instr = gen_j_type_instr(rd, offset);
      
      // Update register tracking for return address
      if (rd != 0) begin
        reg_values[rd] = pc + 4;  // Return address is PC+4
        reg_valid[rd] = 1;
      end
    end
    else begin  // JALR
      logic [4:0] rd, rs1;
      logic [11:0] offset;
      
      // Usually save return address in ra (x1), sometimes in another register
      rd = ($urandom_range(0, 100) < 80) ? 5'd1 : $urandom_range(1, 31);
      rs1 = choose_valid_reg();
      
      // Random offset
      offset = $urandom & 12'hFFF;
      
      // Generate JALR instruction
      instr = gen_jalr_instr(rd, rs1, offset);
      
      // Update register tracking for return address
      if (rd != 0) begin
        reg_values[rd] = pc + 4;  // Return address is PC+4
        reg_valid[rd] = 1;
      end
    end
    
    return instr;
  endfunction
  
  // Process store transaction
  virtual function void process_store_transaction(yarp_seq_item item);
    logic [31:0] addr = calculate_mem_addr(item);
    logic [31:0] data;
    logic [1:0] byte_en;
    
    // Get register data to store
    if (reg_valid[item.rs2]) begin
      data = reg_values[item.rs2];
    end else begin
      data = $urandom;  // Random value if register not tracked
    end
    
    // Determine byte enable based on funct3
    case (item.funct3)
      3'b000: byte_en = 2'b00;  // SB
      3'b001: byte_en = 2'b01;  // SH
      3'b010: byte_en = 2'b11;  // SW
      default: byte_en = 2'b11;
    endcase
    
    // Create data write transaction
    yarp_seq_item mem_item = create_data_write(addr, data, byte_en);
    start_item(mem_item);
    finish_item(mem_item);
  endfunction
  
  // Process load transaction
  virtual function void process_load_transaction(yarp_seq_item item);
    logic [31:0] addr = calculate_mem_addr(item);
    logic [31:0] data = $urandom;  // Random data
    logic [1:0] byte_en;
    
    // Determine byte enable based on funct3
    case (item.funct3)
      3'b000, 3'b100: byte_en = 2'b00;  // LB, LBU
      3'b001, 3'b101: byte_en = 2'b01;  // LH, LHU
      3'b010:         byte_en = 2'b11;  // LW
      default:        byte_en = 2'b11;
    endcase
    
    // Create data read transaction
    yarp_seq_item mem_item = create_data_read(addr, data, byte_en);
    start_item(mem_item);
    finish_item(mem_item);
  endfunction
  
  // Calculate memory address for load/store
  virtual function logic [31:0] calculate_mem_addr(yarp_seq_item item);
    logic [31:0] addr;
    
    // If rs1 is valid, use its value, otherwise use a default address
    if (reg_valid[item.rs1]) begin
      addr = reg_values[item.rs1] + item.imm;
    end else begin
      addr = 32'h2000 + ($urandom & 32'h0FFF);  // Random address in data range
    end
    
    // Make sure address is within valid range
    if (addr > max_mem_addr) begin
      addr = max_mem_addr;
    end
    
    // Make sure address alignment matches access type
    case (item.funct3)
      3'b000, 3'b100: ; // Byte access - any alignment is fine
      3'b001, 3'b101: addr = addr & ~32'h1;  // Half-word access - align to 2 bytes
      3'b010:         addr = addr & ~32'h3;  // Word access - align to 4 bytes
      default:        addr = addr & ~32'h3;
    endcase
    
    return addr;
  endfunction
  
  // Choose a valid register for source operands
  virtual function logic [4:0] choose_valid_reg();
    // First check if we have any valid registers
    int valid_count = 0;
    foreach (reg_valid[i]) begin
      if (reg_valid[i]) valid_count++;
    end
    
    // If we have at least one valid reg, choose randomly among them
    if (valid_count > 0) begin
      int random_pick = $urandom_range(0, valid_count - 1);
      int count = 0;
      
      for (int i = 0; i < 32; i++) begin
        if (reg_valid[i]) begin
          if (count == random_pick) return i[4:0];
          count++;
        end
      end
    end
    
    // If no valid regs or something went wrong, choose completely randomly
    return $urandom_range(0, 31);
  endfunction
  
  // Update register tracking after R-type ALU operation
  virtual function void update_reg_after_alu_op(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, 
                                              logic [2:0] funct3, logic funct7_5);
    // Only track if destination is not x0
    if (rd == 0) return;
    
    // Only track if source regs are valid
    if (!reg_valid[rs1] || !reg_valid[rs2]) begin
      reg_valid[rd] = 0;
      return;
    end
    
    // Calculate new register value based on operation
    logic [3:0] op = {funct7_5, funct3};
    logic [31:0] rs1_val = reg_values[rs1];
    logic [31:0] rs2_val = reg_values[rs2];
    
    case (op)
      4'h0: reg_values[rd] = rs1_val + rs2_val;                          // ADD
      4'h8: reg_values[rd] = rs1_val - rs2_val;                          // SUB
      4'h1: reg_values[rd] = rs1_val << rs2_val[4:0];                    // SLL
      4'h2: reg_values[rd] = ($signed(rs1_val) < $signed(rs2_val)) ? 1 : 0; // SLT
      4'h3: reg_values[rd] = (rs1_val < rs2_val) ? 1 : 0;                // SLTU
      4'h4: reg_values[rd] = rs1_val ^ rs2_val;                          // XOR
      4'h5: reg_values[rd] = rs1_val >> rs2_val[4:0];                    // SRL
      4'hd: reg_values[rd] = $signed(rs1_val) >>> rs2_val[4:0];          // SRA
      4'h6: reg_values[rd] = rs1_val | rs2_val;                          // OR
      4'h7: reg_values[rd] = rs1_val & rs2_val;                          // AND
      default: reg_values[rd] = 0;
    endcase
    
    reg_valid[rd] = 1;
  endfunction
  
  // Update register tracking after I-type ALU operation
  virtual function void update_reg_after_i_alu_op(logic [4:0] rd, logic [4:0] rs1, 
                                                logic [2:0] funct3, logic [11:0] imm);
    // Only track if destination is not x0
    if (rd == 0) return;
    
    // Only track if source reg is valid
    if (!reg_valid[rs1]) begin
      reg_valid[rd] = 0;
      return;
    end
    
    // Sign extend immediate for most operations
    logic [31:0] imm_val = {{20{imm[11]}}, imm};
    logic [31:0] rs1_val = reg_values[rs1];
    
    case (funct3)
      3'b000: reg_values[rd] = rs1_val + imm_val;                     // ADDI
      3'b010: reg_values[rd] = ($signed(rs1_val) < $signed(imm_val)) ? 1 : 0; // SLTI
      3'b011: reg_values[rd] = (rs1_val < imm_val) ? 1 : 0;           // SLTIU
      3'b100: reg_values[rd] = rs1_val ^ imm_val;                     // XORI
      3'b110: reg_values[rd] = rs1_val | imm_val;                     // ORI
      3'b111: reg_values[rd] = rs1_val & imm_val;                     // ANDI
      3'b001: reg_values[rd] = rs1_val << imm[4:0];                   // SLLI
      3'b101: begin
        if (imm[10]) // SRAI
          reg_values[rd] = $signed(rs1_val) >>> imm[4:0];
        else          // SRLI
          reg_values[rd] = rs1_val >> imm[4:0];
      end
      default: reg_values[rd] = 0;
    endcase
    
    reg_valid[rd] = 1;
  endfunction
  
  // Helper to generate a store instruction with specific funct3
  virtual function logic [31:0] gen_store_instr(logic [1:0] size, 
                                              logic [4:0] rs2, 
                                              logic [4:0] rs1, 
                                              logic [11:0] offset);
    logic [31:0] instr;
    logic [2:0] funct3;
    
    // Determine funct3 based on size
    case (size)
      2'b00:   funct3 = 3'b000;  // sb
      2'b01:   funct3 = 3'b001;  // sh
      2'b11:   funct3 = 3'b010;  // sw
      default: funct3 = 3'b010;  // Default to sw
    endcase
    
    // Create S-type instruction (store)
    instr = {offset[11:5], rs2, rs1, funct3, offset[4:0], 7'h23};
    
    return instr;
  endfunction
  
  // Helper to generate a load instruction with specific funct3
  virtual function logic [31:0] gen_load_instr(logic [1:0] size, 
                                             logic [4:0] rd, 
                                             logic [4:0] rs1, 
                                             logic [11:0] offset);
    logic [31:0] instr;
    logic [2:0] funct3;
    
    // Determine funct3 based on size (sign-extended loads)
    case (size)
      2'b00:   funct3 = 3'b000;  // lb
      2'b01:   funct3 = 3'b001;  // lh
      2'b11:   funct3 = 3'b010;  // lw
      default: funct3 = 3'b010;  // Default to lw
    endcase
    
    // Create I-type instruction (load)
    instr = {offset, rs1, funct3, rd, 7'h03};
    
    return instr;
  endfunction
  
  // Helper to generate a zero-extended load instruction
  virtual function logic [31:0] gen_load_instr_zero_ext(logic [1:0] size, 
                                                      logic [4:0] rd, 
                                                      logic [4:0] rs1, 
                                                      logic [11:0] offset);
    logic [31:0] instr;
    logic [2:0] funct3;
    
    // Determine funct3 based on size (zero-extended loads)
    case (size)
      2'b00:   funct3 = 3'b100;  // lbu
      2'b01:   funct3 = 3'b101;  // lhu
      default: funct3 = 3'b010;  // Default to lw (no zero-extended word load)
    endcase
    
    // Create I-type instruction (load)
    instr = {offset, rs1, funct3, rd, 7'h03};
    
    return instr;
  endfunction
  
  // Helper to generate an I-type ALU instruction with specific funct3
  virtual function logic [31:0] gen_i_type_alu(logic [2:0] funct3, 
                                             logic [4:0] rd, 
                                             logic [4:0] rs1, 
                                             logic [11:0] imm);
    logic [31:0] instr;
    
    // Create I-type ALU instruction
    instr = {imm, rs1, funct3, rd, 7'h13};
    
    return instr;
  endfunction
  
  // Helper to generate a JALR instruction
  virtual function logic [31:0] gen_jalr_instr(logic [4:0] rd, 
                                             logic [4:0] rs1, 
                                             logic [11:0] offset);
    logic [31:0] instr;
    
    // Create JALR instruction (I-type with special opcode)
    instr = {offset, rs1, 3'b000, rd, 7'h67};
    
    return instr;
  endfunction
  
  // Helper to generate R-type instruction with specific funct3 and funct7[5]
  virtual function logic [31:0] gen_r_type_with_funct(logic [2:0] funct3, logic funct7_5, 
                                                    logic [4:0] rd = 5'd1, logic [4:0] rs1 = 5'd2, 
                                                    logic [4:0] rs2 = 5'd3);
    logic [31:0] instr;
    
    // Create R-type instruction with specific function codes
    instr = {7'b0, rs2, rs1, funct3, rd, 7'h33};
    
    // Set funct7[5] if needed
    if (funct7_5) begin
      instr[30] = 1'b1;  // Set bit 30 (funct7[5])
    end
    
    return instr;
  endfunction
  
  // Helper to generate a branch instruction with specific funct3 and immediates
  virtual function logic [31:0] gen_branch_instruction(logic [2:0] funct3, 
                                                     logic [4:0] rs1, 
                                                     logic [4:0] rs2, 
                                                     logic [12:0] imm12);
    logic [31:0] instr;
    
    // Break down the immediate value into its parts for B-type encoding
    logic imm11;
    logic [3:0] imm4_1;
    logic [5:0] imm10_5;
    logic imm12bit;
    
    imm11 = imm12[11];
    imm4_1 = imm12[4:1];
    imm10_5 = imm12[10:5];
    imm12bit = imm12[12];
    
    // Create B-type instruction
    instr = {imm12bit, imm11, imm10_5, rs2, rs1, funct3, imm4_1, 1'b0, 7'h63};
    
    return instr;
  endfunction
  
  // Helper function to generate a J-type instruction (JAL)
  virtual function logic [31:0] gen_j_type_instr(logic [4:0] rd = 0, logic [20:0] imm = 0);
    logic [31:0] instr;
    
    // Break down the immediate value into its parts for J-type encoding
    logic [7:0] imm19_12 = imm[19:12];
    logic imm11 = imm[11];
    logic [9:0] imm10_1 = imm[10:1];
    logic imm20 = imm[20];
    
    // Create J-type instruction
    instr = {imm20, imm10_1, imm11, imm19_12, rd, 7'h6F};
    
    return instr;
  endfunction
  
  // Helper function to generate a U-type instruction (lui or auipc)
  virtual function logic [31:0] gen_u_type_instr(logic u_type = 1'b0, logic [4:0] rd = 0, logic [19:0] imm20 = 0);
    logic [31:0] instr;
    logic [6:0] op;
    
    // Determine opcode based on U-type subtype
    op = u_type ? 7'h17 : 7'h37;  // AUIPC or LUI
    
    // Create U-type instruction
    instr = {imm20, rd, op};
    
    return instr;
  endfunction
  
endclass
