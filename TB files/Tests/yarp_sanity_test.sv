// YARP Sanity Test - Basic processor functionality check
class yarp_sanity_test extends yarp_base_test;
  // Registration with factory
  `uvm_component_utils(yarp_sanity_test)
  
  // Constructor
  function new(string name = "yarp_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Test-specific sequence
  virtual task run_test_sequence(uvm_phase phase);
    yarp_sanity_seq seq;
    
    // Create and start the sanity sequence
    seq = yarp_sanity_seq::type_id::create("seq");
    
    `uvm_info(get_type_name(), "Starting sanity test sequence", UVM_LOW)
    
    if (!seq.randomize()) begin
      `uvm_error(get_type_name(), "Failed to randomize sequence")
    end
    
    seq.start(env.agent.sequencer);
    
    `uvm_info(get_type_name(), "Sanity test sequence completed", UVM_LOW)
  endtask
  
endclass

// Sanity sequence for basic functionality testing
class yarp_sanity_seq extends yarp_base_seq;
  // Registration with factory
  `uvm_object_utils(yarp_sanity_seq)
  
  // Constructor
  function new(string name = "yarp_sanity_seq");
    super.new(name);
    min_instr_count = 5;
    max_instr_count = 15;
  endfunction
  
  // Body task - generates the sequence
  virtual task body();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = 32'h1000;  // Default reset PC
    
    `uvm_info(get_type_name(), "Executing sanity test sequence", UVM_MEDIUM)
    
    // 1. Initialize x1 with a constant
    instr = gen_i_type_alu(3'b000, 5'd1, 5'd0, 12'h123);  // addi x1, x0, 0x123
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // 2. Initialize x2 with another constant
    instr = gen_i_type_alu(3'b000, 5'd2, 5'd0, 12'h456);  // addi x2, x0, 0x456
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // 3. Add x1 and x2, store in x3
    instr = gen_r_type_with_funct(3'b000, 1'b0, 5'd3, 5'd1, 5'd2);  // add x3, x1, x2
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // 4. Store x3 to memory address 0x2000
    instr = gen_store_instr(2'b11, 5'd3, 5'd0, 12'h2000);  // sw x3, 0x2000(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory write transaction
    item = create_data_write(32'h2000, 32'h579, 2'b11);  // 0x123 + 0x456 = 0x579
    start_item(item);
    finish_item(item);
    
    // 5. Load from memory address 0x2000 to x4
    instr = gen_load_instr(2'b11, 5'd4, 5'd0, 12'h2000);  // lw x4, 0x2000(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction
    item = create_data_read(32'h2000, 32'h579, 2'b11);
    start_item(item);
    finish_item(item);
    
    // 6. Compare x3 and x4 (should be equal)
    instr = gen_branch_instruction(3'b000, 5'd3, 5'd4, 12'h008);  // beq x3, x4, +8
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // 7. Skip the next instruction (branch target)
    pc += 8;
    
    // 8. Final instruction - add x3 and x4, store in x5
    instr = gen_r_type_with_funct(3'b000, 1'b0, 5'd5, 5'd3, 5'd4);  // add x5, x3, x4
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    
    `uvm_info(get_type_name(), "Sanity test sequence completed successfully", UVM_MEDIUM)
  endtask
  
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
  
  // Helper function to generate an I-type ALU instruction with specific funct3
  virtual function logic [31:0] gen_i_type_alu(logic [2:0] funct3, 
                                             logic [4:0] rd, 
                                             logic [4:0] rs1, 
                                             logic [11:0] imm);
    logic [31:0] instr;
    
    // Create I-type ALU instruction
    instr = {imm, rs1, funct3, rd, 7'h13};
    
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
                                                     logic [11:0] imm12);
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
  
endclass
