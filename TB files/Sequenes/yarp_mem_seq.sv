// YARP Memory Sequence - Tests memory load/store operations
class yarp_mem_seq extends yarp_base_seq;
  // Registration with factory
  `uvm_object_utils(yarp_mem_seq)
  
  // Variables to control test generation
  bit test_all_mem_access_types = 1;  // Test all memory access types (byte, half-word, word)
  bit test_mem_alignment = 1;         // Test memory alignment cases
  
  // Address ranges
  logic [31:0] data_mem_start = 32'h2000;
  logic [31:0] main_program_addr = 32'h1000;
  
  // Constructor
  function new(string name = "yarp_mem_seq");
    super.new(name);
  endfunction
  
  // Body task - generates the sequence
  virtual task body();
    // Test all memory access types if enabled
    if (test_all_mem_access_types) begin
      test_memory_access_types();
    end
    
    // Test memory alignment if enabled
    if (test_mem_alignment) begin
      test_memory_alignment();
    end
    
    // Test memory access patterns
    test_memory_patterns();
  endtask
  
  // Test all memory access types (byte, half-word, word)
  virtual task test_memory_access_types();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr;
    
    `uvm_info(get_type_name(), "Testing all memory access types", UVM_MEDIUM)
    
    // Initialize registers with test values
    initialize_registers(pc);
    pc += 20;  // Skip 5 instructions (4 bytes each)
    
    // -------------------------------------------------------------------------
    // Word access tests (lw, sw)
    // -------------------------------------------------------------------------
    
    // Store word (x1 to mem[2000])
    instr = gen_store_instr(2'b11, 5'd1, 5'd0, 12'h2000);  // sw x1, 0x2000(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Now create the data memory write transaction that we expect to happen
    item = create_data_write(32'h2000, reg_file[1], 2'b11);
    start_item(item);
    finish_item(item);
    
    // Load word (mem[2000] to x2)
    instr = gen_load_instr(2'b11, 5'd2, 5'd0, 12'h2000);  // lw x2, 0x2000(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction that we expect to happen
    item = create_data_read(32'h2000, reg_file[1], 2'b11);
    start_item(item);
    finish_item(item);
    
    // -------------------------------------------------------------------------
    // Half-word access tests (lh, lhu, sh)
    // -------------------------------------------------------------------------
    
    // Store half-word (x1 to mem[2004])
    instr = gen_store_instr(2'b01, 5'd1, 5'd0, 12'h2004);  // sh x1, 0x2004(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory write transaction that we expect to happen
    item = create_data_write(32'h2004, reg_file[1] & 16'hFFFF, 2'b01);
    start_item(item);
    finish_item(item);
    
    // Load half-word with sign extension (mem[2004] to x3)
    instr = gen_load_instr(2'b01, 5'd3, 5'd0, 12'h2004);  // lh x3, 0x2004(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction that we expect to happen
    item = create_data_read(32'h2004, {{16{reg_file[1][15]}}, reg_file[1][15:0]}, 2'b01);
    start_item(item);
    finish_item(item);
    
    // Load half-word with zero extension (mem[2004] to x4)
    instr = gen_load_instr_zero_ext(2'b01, 5'd4, 5'd0, 12'h2004);  // lhu x4, 0x2004(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction that we expect to happen
    item = create_data_read(32'h2004, {{16{1'b0}}, reg_file[1][15:0]}, 2'b01);
    start_item(item);
    finish_item(item);
    
    // -------------------------------------------------------------------------
    // Byte access tests (lb, lbu, sb)
    // -------------------------------------------------------------------------
    
    // Store byte (x1 to mem[2008])
    instr = gen_store_instr(2'b00, 5'd1, 5'd0, 12'h2008);  // sb x1, 0x2008(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory write transaction that we expect to happen
    item = create_data_write(32'h2008, reg_file[1] & 8'hFF, 2'b00);
    start_item(item);
    finish_item(item);
    
    // Load byte with sign extension (mem[2008] to x5)
    instr = gen_load_instr(2'b00, 5'd5, 5'd0, 12'h2008);  // lb x5, 0x2008(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction that we expect to happen
    item = create_data_read(32'h2008, {{24{reg_file[1][7]}}, reg_file[1][7:0]}, 2'b00);
    start_item(item);
    finish_item(item);
    
    // Load byte with zero extension (mem[2008] to x6)
    instr = gen_load_instr_zero_ext(2'b00, 5'd6, 5'd0, 12'h2008);  // lbu x6, 0x2008(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction that we expect to happen
    item = create_data_read(32'h2008, {{24{1'b0}}, reg_file[1][7:0]}, 2'b00);
    start_item(item);
    finish_item(item);
  endtask
  
  // Test memory alignment (aligned vs. unaligned accesses)
  virtual task test_memory_alignment();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr + 32'h100;  // Offset from main program
    
    `uvm_info(get_type_name(), "Testing memory alignment", UVM_MEDIUM)
    
    // Initialize registers with test values
    initialize_registers(pc);
    pc += 20;  // Skip 5 instructions (4 bytes each)
    
    // -------------------------------------------------------------------------
    // Aligned word access (address % 4 = 0)
    // -------------------------------------------------------------------------
    
    // Store word at aligned address (x1 to mem[2100])
    instr = gen_store_instr(2'b11, 5'd1, 5'd0, 12'h2100);  // sw x1, 0x2100(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory write transaction
    item = create_data_write(32'h2100, reg_file[1], 2'b11);
    start_item(item);
    finish_item(item);
    
    // Load word from aligned address (mem[2100] to x2)
    instr = gen_load_instr(2'b11, 5'd2, 5'd0, 12'h2100);  // lw x2, 0x2100(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction
    item = create_data_read(32'h2100, reg_file[1], 2'b11);
    start_item(item);
    finish_item(item);
    
    // -------------------------------------------------------------------------
    // Unaligned half-word access (address % 2 = 1)
    // -------------------------------------------------------------------------
    
    // Store half-word at unaligned address (x1 to mem[2101])
    instr = gen_store_instr(2'b01, 5'd1, 5'd0, 12'h2101);  // sh x1, 0x2101(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // This should be aligned to 2-byte boundary by hardware, so we expect:
    item = create_data_write(32'h2100, (reg_file[1] & 16'hFFFF) << 8, 2'b01);
    start_item(item);
    finish_item(item);
    
    // Load half-word from unaligned address (mem[2101] to x3)
    instr = gen_load_instr(2'b01, 5'd3, 5'd0, 12'h2101);  // lh x3, 0x2101(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction
    item = create_data_read(32'h2100, {{16{reg_file[1][15]}}, reg_file[1][15:0]}, 2'b01);
    start_item(item);
    finish_item(item);
    
    // -------------------------------------------------------------------------
    // Half-word access at different alignments
    // -------------------------------------------------------------------------
    
    // Store half-word at address 0x2102 (aligned)
    instr = gen_store_instr(2'b01, 5'd1, 5'd0, 12'h2102);  // sh x1, 0x2102(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory write transaction
    item = create_data_write(32'h2102, reg_file[1] & 16'hFFFF, 2'b01);
    start_item(item);
    finish_item(item);
    
    // Load half-word from address 0x2102 (aligned)
    instr = gen_load_instr(2'b01, 5'd4, 5'd0, 12'h2102);  // lh x4, 0x2102(x0)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Create the data memory read transaction
    item = create_data_read(32'h2102, {{16{reg_file[1][15]}}, reg_file[1][15:0]}, 2'b01);
    start_item(item);
    finish_item(item);
    
    // -------------------------------------------------------------------------
    // Byte access at different alignments
    // -------------------------------------------------------------------------
    
    // Store bytes at addresses 0x2104, 0x2105, 0x2106, 0x2107
    for (int i = 0; i < 4; i++) begin
      instr = gen_store_instr(2'b00, 5'd1, 5'd0, 12'h2104 + i);  // sb x1, (0x2104+i)(x0)
      instr_mem[pc] = instr;
      item = create_instr_fetch(pc, instr);
      start_item(item);
      finish_item(item);
      pc += 4;
      
      // Create the data memory write transaction
      item = create_data_write(32'h2104 + i, reg_file[1] & 8'hFF, 2'b00);
      start_item(item);
      finish_item(item);
    end
    
    // Load bytes from addresses 0x2104, 0x2105, 0x2106, 0x2107
    for (int i = 0; i < 4; i++) begin
      instr = gen_load_instr(2'b00, 5'd5+i, 5'd0, 12'h2104 + i);  // lb x(5+i), (0x2104+i)(x0)
      instr_mem[pc] = instr;
      item = create_instr_fetch(pc, instr);
      start_item(item);
      finish_item(item);
      pc += 4;
      
      // Create the data memory read transaction
      item = create_data_read(32'h2104 + i, {{24{reg_file[1][7]}}, reg_file[1][7:0]}, 2'b00);
      start_item(item);
      finish_item(item);
    end
  endtask
  
  // Test memory access patterns (sequential, strided, etc.)
  virtual task test_memory_patterns();
    yarp_seq_item item;
    logic [31:0] instr;
    logic [31:0] pc = main_program_addr + 32'h200;  // Offset from main program
    
    `uvm_info(get_type_name(), "Testing memory access patterns", UVM_MEDIUM)
    
    // Initialize registers with test values
    initialize_registers(pc);
    pc += 20;  // Skip 5 instructions (4 bytes each)
    
    // -------------------------------------------------------------------------
    // Sequential access pattern (array traversal)
    // -------------------------------------------------------------------------
    
    // Initialize array of 10 words with increasing values
    for (int i = 0; i < 10; i++) begin
      // Set x1 to loop index value (i)
      instr = gen_i_type_alu(3'b000, 5'd1, 5'd0, i & 12'hFFF);  // addi x1, x0, i
      instr_mem[pc] = instr;
      item = create_instr_fetch(pc, instr);
      start_item(item);
      finish_item(item);
      pc += 4;
      
      // Store word (x1 to mem[2200 + i*4])
      instr = gen_store_instr(2'b11, 5'd1, 5'd0, 12'h2200 + (i*4));  // sw x1, (0x2200+i*4)(x0)
      instr_mem[pc] = instr;
      item = create_instr_fetch(pc, instr);
      start_item(item);
      finish_item(item);
      pc += 4;
      
      // Create the data memory write transaction
      item = create_data_write(32'h2200 + (i*4), i, 2'b11);
      start_item(item);
      finish_item(item);
    end
    
    // Initialize loop counter (x2 = 0)
    instr = gen_i_type_alu(3'b000, 5'd2, 5'd0, 12'h0);  // addi x2, x0, 0
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Initialize sum accumulator (x3 = 0)
    instr = gen_i_type_alu(3'b000, 5'd3, 5'd0, 12'h0);  // addi x3, x0, 0
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Loop start
    logic [31:0] loop_start = pc;
    
    // Load array element (mem[2200 + x2*4] to x1)
    instr = gen_load_indexed(2'b11, 5'd1, 5'd2, 12'h2200);  // lw x1, 0x2200(x2)
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Add to accumulator (x3 += x1)
    instr = gen_r_type_with_funct(3'b000, 1'b0, 5'd3, 5'd3, 5'd1);  // add x3, x3, x1
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Increment counter (x2 += 4)
    instr = gen_i_type_alu(3'b000, 5'd2, 5'd2, 12'h4);  // addi x2, x2, 4
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // Check if at end of array (x2 < 40)
    instr = gen_branch_instruction(3'b100, 5'd2, 5'd7, -12 & 12'hFFF);  // blt x2, x7, loop_start
    instr_mem[pc] = instr;
    item = create_instr_fetch(pc, instr);
    start_item(item);
    finish_item(item);
    pc += 4;
    
    // -------------------------------------------------------------------------
    // Strided access pattern (matrix traversal)
    // -------------------------------------------------------------------------
    
    // ... (additional memory access patterns could be added here)
  endtask
  
  // Helper to initialize registers with test values
  virtual task initialize_registers(logic [31:0] pc);
    yarp_seq_item item;
    
    // Set x1 to 0x12345678
    instr_mem[pc] = gen_u_type_instr(1'b0, 5'd1, 20'h12345);  // lui x1, 0x12345
    instr_mem[pc+4] = gen_i_type_alu(3'b000, 5'd1, 5'd1, 12'h678);  // addi x1, x1, 0x678
    
    // Store value for test reference
    reg_file[1] = 32'h12345678;
    
    // Set x7 to 40 (for loop bound checking)
    instr_mem[pc+8] = gen_i_type_alu(3'b000, 5'd7, 5'd0, 12'h28);  // addi x7, x0, 40
    
    // Store value for test reference
    reg_file[7] = 32'h28;  // 40 in decimal
    
    // Set x8 to 0xF0000000 (for sign extension tests)
    instr_mem[pc+12] = gen_u_type_instr(1'b0, 5'd8, 20'hF0000);  // lui x8, 0xF0000
    
    // Store value for test reference
    reg_file[8] = 32'hF0000000;
    
    // Set x9 to 0x0000000F (for zero extension tests)
    instr_mem[pc+16] = gen_i_type_alu(3'b000, 5'd9, 5'd0, 12'hF);  // addi x9, x0, 0xF
    
    // Store value for test reference
    reg_file[9] = 32'h0000000F;
    
    // Fetch all initialization instructions
    for (int i = 0; i < 5; i++) begin
      item = create_instr_fetch(pc + (i*4), instr_mem[pc + (i*4)]);
      start_item(item);
      finish_item(item);
    end
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
  
  // Helper to generate a zero-extended load instruction with specific funct3
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
  
  // Helper to generate an indexed load instruction (for array access)
  virtual function logic [31:0] gen_load_indexed(logic [1:0] size, 
                                               logic [4:0] rd, 
                                               logic [4:0] rs1, 
                                               logic [11:0] base_offset);
    // Simply use the standard load instruction generator
    // The offset is the base address, and rs1 contains the index (scaled appropriately)
    return gen_load_instr(size, rd, rs1, base_offset);
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
