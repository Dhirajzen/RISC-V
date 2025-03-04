// YARP Branch Sequence - Tests branch operations
class yarp_branch_seq extends yarp_base_seq;
  // Registration with factory
  `uvm_object_utils(yarp_branch_seq)
  
  // Variables to control test generation
  bit test_all_branch_types = 1;  // Test all branch conditions
  bit test_branch_edge_cases = 1; // Test boundary conditions for branches
  
  // Address for main program
  logic [31:0] main_program_addr = 32'h1000;
  
  // Constructor
  function new(string name = "yarp_branch_seq");
    super.new(name);
  endfunction
  
  // Body task - generates the sequence
  virtual task body();
    // Test all branch types if enabled
    if (test_all_branch_types) begin
      test_branch_conditions();
    end
    
    // Test branch edge cases if enabled
    if (test_branch_edge_cases) begin
      test_branch_boundaries();
    end
    
    // Test forward and backward branches
    test_forward_backward_branches();
  endtask
  
  // Test all branch conditions
  virtual task test_branch_conditions();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr;
    
    `uvm_info(get_type_name(), "Testing all branch conditions", UVM_MEDIUM)
    
    // Initialize registers with test values
    initialize_registers(pc);
    pc += 16;  // Skip 4 instructions (4 bytes each)
    
    // Test BEQ (Branch if Equal) - Should branch
    instr = gen_branch_instruction(3'b000, 5'd1, 5'd1, 12'h10);  // beq x1, x1, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BEQ (Branch if Equal) - Should not branch
    instr = gen_branch_instruction(3'b000, 5'd1, 5'd2, 12'h10);  // beq x1, x2, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Test BNE (Branch if Not Equal) - Should branch
    instr = gen_branch_instruction(3'b001, 5'd1, 5'd2, 12'h10);  // bne x1, x2, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BNE (Branch if Not Equal) - Should not branch
    instr = gen_branch_instruction(3'b001, 5'd1, 5'd1, 12'h10);  // bne x1, x1, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Test BLT (Branch if Less Than) - Should branch
    instr = gen_branch_instruction(3'b100, 5'd8, 5'd9, 12'h10);  // blt x8, x9, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BLT (Branch if Less Than) - Should not branch
    instr = gen_branch_instruction(3'b100, 5'd9, 5'd8, 12'h10);  // blt x9, x8, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Test BGE (Branch if Greater or Equal) - Should branch
    instr = gen_branch_instruction(3'b101, 5'd9, 5'd8, 12'h10);  // bge x9, x8, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BGE (Branch if Greater or Equal) - Should not branch
    instr = gen_branch_instruction(3'b101, 5'd8, 5'd9, 12'h10);  // bge x8, x9, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Test BLTU (Branch if Less Than Unsigned) - Should branch
    instr = gen_branch_instruction(3'b110, 5'd10, 5'd11, 12'h10);  // bltu x10, x11, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BLTU (Branch if Less Than Unsigned) - Should not branch
    instr = gen_branch_instruction(3'b110, 5'd11, 5'd10, 12'h10);  // bltu x11, x10, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Test BGEU (Branch if Greater or Equal Unsigned) - Should branch
    instr = gen_branch_instruction(3'b111, 5'd11, 5'd10, 12'h10);  // bgeu x11, x10, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test BGEU (Branch if Greater or Equal Unsigned) - Should not branch
    instr = gen_branch_instruction(3'b111, 5'd10, 5'd11, 12'h10);  // bgeu x10, x11, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
  endtask
  
  // Test branch boundary conditions
  virtual task test_branch_boundaries();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr + 32'h100;  // Start at offset from main program
    
    `uvm_info(get_type_name(), "Testing branch boundary conditions", UVM_MEDIUM)
    
    // Initialize registers with special boundary values
    initialize_boundary_registers(pc);
    pc += 24;  // Skip 6 instructions (4 bytes each)
    
    // Test equal to zero condition
    instr = gen_branch_instruction(3'b000, 5'd5, 5'd0, 12'h10);  // beq x5, x0, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test equal to max positive condition
    instr = gen_branch_instruction(3'b000, 5'd6, 5'd7, 12'h10);  // beq x6, x7, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test less than with negative and positive
    instr = gen_branch_instruction(3'b100, 5'd8, 5'd5, 12'h10);  // blt x8, x5, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
    
    // Test unsigned comparison with negative and positive
    instr = gen_branch_instruction(3'b110, 5'd5, 5'd8, 12'h10);  // bltu x5, x8, +16
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Skip one instruction (branch target)
    pc += 16;
  endtask
  
  // Test forward and backward branches
  virtual task test_forward_backward_branches();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr + 32'h200;  // Start at offset from main program
    logic [31:0] loop_start, loop_end;
    
    `uvm_info(get_type_name(), "Testing forward and backward branches", UVM_MEDIUM)
    
    // Initialize counter register (x5 = 5)
    instr = gen_i_type_alu(3'b000, 5'd5, 5'd0, 12'h5);  // addi x5, x0, 5
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Initialize another register (x6 = 0)
    instr = gen_i_type_alu(3'b000, 5'd6, 5'd0, 12'h0);  // addi x6, x0, 0
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Loop start (increment x6)
    loop_start = pc;
    instr = gen_i_type_alu(3'b000, 5'd6, 5'd6, 12'h1);  // addi x6, x6, 1
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Decrement counter (x5)
    instr = gen_i_type_alu(3'b000, 5'd5, 5'd5, -1 & 12'hfff);  // addi x5, x5, -1
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Branch back to loop start if counter (x5) > 0
    loop_end = pc;
    instr = gen_branch_instruction(3'b101, 5'd5, 5'd0, (-8 & 12'hfff));  // bge x5, x0, -8
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Final instruction after loop
    instr = gen_i_type_alu(3'b000, 5'd7, 5'd6, 12'h0);  // addi x7, x6, 0 (copy result)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
  endtask
  
  // Helper to initialize registers with test values
  virtual task initialize_registers(logic [31:0] pc);
    yarp_seq_item item;
    
    // Set x1 to 0x12345678
    instr_mem[pc] = gen_u_type_instr(1'b0, 5'd1, 20'h12345);  // lui x1, 0x12345
    instr_mem[pc+4] = gen_i_type_alu(3'b000, 5'd1, 5'd1, 12'h678);  // addi x1, x1, 0x678
    
    // Set x2 to 0x87654321
    instr_mem[pc+8] = gen_u_type_instr(1'b0, 5'd2, 20'h87654);  // lui x2, 0x87654
    instr_mem[pc+12] = gen_i_type_alu(3'b000, 5'd2, 5'd2, 12'h321);  // addi x2, x2, 0x321
    
    // Set x8 to a smaller value (10)
    instr_mem[pc+16] = gen_i_type_alu(3'b000, 5'd8, 5'd0, 12'h0A);  // addi x8, x0, 10
    
    // Set x9 to a larger value (20)
    instr_mem[pc+20] = gen_i_type_alu(3'b000, 5'd9, 5'd0, 12'h14);  // addi x9, x0, 20
    
    // Set x10 to a smaller unsigned value (0xF0000000 - large signed but small unsigned)
    instr_mem[pc+24] = gen_u_type_instr(1'b0, 5'd10, 20'hF0000);  // lui x10, 0xF0000
    
    // Set x11 to a larger unsigned value (0x00000010 - small signed but looks larger unsigned)
    instr_mem[pc+28] = gen_i_type_alu(3'b000, 5'd11, 5'd0, 12'h10);  // addi x11, x0, 0x10
    
    // Fetch all initialization instructions
    for (int i = 0; i < 8; i++) begin
      item = create_instr_fetch(pc + (i*4), instr_mem[pc + (i*4)]);
      start_item(item);
      finish_item(item);
    end
  endtask
  
  // Helper to initialize registers with boundary values
  virtual task initialize_boundary_registers(logic [31:0] pc);
    yarp_seq_item item;
    
    // Set x5 to 0x00000000 (Zero)
    instr_mem[pc] = gen_i_type_alu(3'b000, 5'd5, 5'd0, 12'h0);  // addi x5, x0, 0x0
    
    // Set x6 to 0x7FFFFFFF (Maximum positive)
    instr_mem[pc+4] = gen_u_type_instr(1'b0, 5'd6, 20'h7FFFF);  // lui x6, 0x7FFFF
    instr_mem[pc+8] = gen_i_type_alu(3'b000, 5'd6, 5'd6, 12'hFFF);  // addi x6, x6, 0xFFF
    
    // Set x7 to 0x7FFFFFFF (same as x6 for equality test)
    instr_mem[pc+12] = gen_u_type_instr(1'b0, 5'd7, 20'h7FFFF);  // lui x7, 0x7FFFF
    instr_mem[pc+16] = gen_i_type_alu(3'b000, 5'd7, 5'd7, 12'hFFF);  // addi x7, x7, 0xFFF
    
    // Set x8 to 0x80000000 (Minimum negative)
    instr_mem[pc+20] = gen_u_type_instr(1'b0, 5'd8, 20'h80000);  // lui x8, 0x80000
    
    // Fetch all initialization instructions
    for (int i = 0; i < 6; i++) begin
      item = create_instr_fetch(pc + (i*4), instr_mem[pc + (i*4)]);
      start_item(item);
      finish_item(item);
    end
  endtask
  
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
  
endclass
