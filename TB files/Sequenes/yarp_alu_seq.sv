// YARP ALU Sequence - Tests ALU operations
class yarp_alu_seq extends yarp_base_seq;
  // Registration with factory
  `uvm_object_utils(yarp_alu_seq)
  
  // Variables to control test generation
  bit test_edge_cases = 1;  // Test boundary values
  bit test_all_ops = 1;     // Test all ALU operations
  
  // Constructor
  function new(string name = "yarp_alu_seq");
    super.new(name);
  endfunction
  
  // Body task - generates the sequence
  virtual task body();
    // Test R-type ALU operations
    test_r_type_alu();
    
    // Test I-type ALU operations
    test_i_type_alu();
    
    // Test edge cases if enabled
    if (test_edge_cases) begin
      test_alu_edge_cases();
    end
  endtask
  
  // Test all R-type ALU operations
  virtual task test_r_type_alu();
    bit [3:0] funct_cases[$];
    yarp_seq_item item;
    
    // Define all R-type ALU operation cases to test
    funct_cases = {4'h0, 4'h8, 4'h1, 4'h5, 4'hd, 4'h6, 4'h7, 4'h4, 4'h3, 4'h2};
    
    `uvm_info(get_type_name(), "Testing R-type ALU operations", UVM_MEDIUM)
    
    // Initialize registers
    initialize_registers();
    
    // Generate instructions for each function
    foreach (funct_cases[i]) begin
      logic [2:0] funct3;
      logic funct7_5;
      logic [31:0] instr;
      
      // Extract funct3 and funct7[5] from the combined value
      funct3 = funct_cases[i][2:0];
      funct7_5 = funct_cases[i][3];
      
      // Create R-type instruction
      instr = gen_r_type_with_funct(funct3, funct7_5);
      
      // Store instruction in memory
      instr_mem[32'h1000 + (i*4)] = instr;
      
      // Create instruction fetch transaction
      item = create_instr_fetch(32'h1000 + (i*4), instr);
      
      // Send to sequencer
      start_item(item);
      finish_item(item);
    end
  endtask
  
  // Test all I-type ALU operations
  virtual task test_i_type_alu();
    yarp_seq_item item;
    
    `uvm_info(get_type_name(), "Testing I-type ALU operations", UVM_MEDIUM)
    
    // Initialize registers
    initialize_registers();
    
    // Generate ADDI instruction
    instr_mem[32'h1100] = gen_i_type_alu(3'b000, 5'd1, 5'd0, 12'h123);  // addi x1, x0, 0x123
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1100, instr_mem[32'h1100]);
    start_item(item);
    finish_item(item);
    
    // Generate SLTI instruction
    instr_mem[32'h1104] = gen_i_type_alu(3'b010, 5'd2, 5'd1, 12'h234);  // slti x2, x1, 0x234
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1104, instr_mem[32'h1104]);
    start_item(item);
    finish_item(item);
    
    // Generate SLTIU instruction
    instr_mem[32'h1108] = gen_i_type_alu(3'b011, 5'd3, 5'd1, 12'hfff);  // sltiu x3, x1, 0xfff
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1108, instr_mem[32'h1108]);
    start_item(item);
    finish_item(item);
    
    // Generate XORI instruction
    instr_mem[32'h110C] = gen_i_type_alu(3'b100, 5'd4, 5'd1, 12'h456);  // xori x4, x1, 0x456
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h110C, instr_mem[32'h110C]);
    start_item(item);
    finish_item(item);
    
    // Generate ORI instruction
    instr_mem[32'h1110] = gen_i_type_alu(3'b110, 5'd5, 5'd1, 12'h789);  // ori x5, x1, 0x789
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1110, instr_mem[32'h1110]);
    start_item(item);
    finish_item(item);
    
    // Generate ANDI instruction
    instr_mem[32'h1114] = gen_i_type_alu(3'b111, 5'd6, 5'd1, 12'hcba);  // andi x6, x1, 0xcba
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1114, instr_mem[32'h1114]);
    start_item(item);
    finish_item(item);
    
    // Generate SLLI instruction
    instr_mem[32'h1118] = gen_i_type_alu(3'b001, 5'd7, 5'd1, 12'h004);  // slli x7, x1, 4
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1118, instr_mem[32'h1118]);
    start_item(item);
    finish_item(item);
    
    // Generate SRLI instruction
    instr_mem[32'h111C] = gen_i_type_alu(3'b101, 5'd8, 5'd1, 12'h002);  // srli x8, x1, 2
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h111C, instr_mem[32'h111C]);
    start_item(item);
    finish_item(item);
    
    // Generate SRAI instruction
    instr_mem[32'h1120] = gen_i_type_alu_srai(5'd9, 5'd1, 5'd3);  // srai x9, x1, 3
    
    // Create instruction fetch transaction
    item = create_instr_fetch(32'h1120, instr_mem[32'h1120]);
    start_item(item);
    finish_item(item);
  endtask
  
  // Test ALU edge cases
  virtual task test_alu_edge_cases();
    yarp_seq_item item;
    
    `uvm_info(get_type_name(), "Testing ALU edge cases", UVM_MEDIUM)
    
    // Test overflow cases
    
    // Set register x1 to maximum positive value
    instr_mem[32'h1200] = gen_i_type_alu(3'b000, 5'd1, 5'd0, 12'hfff);  // addi x1, x0, 0xfff
    item = create_instr_fetch(32'h1200, instr_mem[32'h1200]);
    start_item(item);
    finish_item(item);
    
    // Logical shift left by 20 bits (overflow check)
    instr_mem[32'h1204] = gen_i_type_alu(3'b001, 5'd2, 5'd1, 12'h014);  // slli x2, x1, 20
    item = create_instr_fetch(32'h1204, instr_mem[32'h1204]);
    start_item(item);
    finish_item(item);
    
    // Set register x3 to negative value
    instr_mem[32'h1208] = gen_i_type_alu(3'b000, 5'd3, 5'd0, 12'h800);  // addi x3, x0, 0x800 (sign extended)
    item = create_instr_fetch(32'h1208, instr_mem[32'h1208]);
    start_item(item);
    finish_item(item);
    
    // Arithmetic right shift (sign extension check)
    instr_mem[32'h120C] = gen_i_type_alu_srai(5'd4, 5'd3, 5'd4);  // srai x4, x3, 4
    item = create_instr_fetch(32'h120C, instr_mem[32'h120C]);
    start_item(item);
    finish_item(item);
    
    // Test zero operand case
    instr_mem[32'h1210] = gen_r_type_with_funct(3'b000, 1'b1, 5'd5, 5'd0, 5'd0);  // sub x5, x0, x0
    item = create_instr_fetch(32'h1210, instr_mem[32'h1210]);
    start_item(item);
    finish_item(item);
    
    // Test division by zero (using SUB to see if result is correctly handled)
    instr_mem[32'h1214] = gen_r_type_with_funct(3'b000, 1'b1, 5'd6, 5'd1, 5'd0);  // sub x6, x1, x0
    item = create_instr_fetch(32'h1214, instr_mem[32'h1214]);
    start_item(item);
    finish_item(item);
  endtask
  
  // Helper to initialize registers with known values
  virtual task initialize_registers();
    // Create register-setting instructions
    // Set x1 to 0x55555555
    instr_mem[32'h1000] = gen_u_type_instr(1'b0, 5'd1, 20'h55555);  // lui x1, 0x55555
    
    // Set x2 to 0xAAAAAAAA
    instr_mem[32'h1004] = gen_u_type_instr(1'b0, 5'd2, 20'hAAAAA);  // lui x2, 0xAAAAA
    
    // Set x3 to 0x12345678
    instr_mem[32'h1008] = gen_u_type_instr(1'b0, 5'd3, 20'h12345);  // lui x3, 0x12345
    instr_mem[32'h100C] = gen_i_type_alu(3'b000, 5'd3, 5'd3, 12'h678);  // addi x3, x3, 0x678
    
    // Set x4 to 0x0
    instr_mem[32'h1010] = gen_i_type_alu(3'b000, 5'd4, 5'd0, 12'h0);  // addi x4, x0, 0x0
    
    // Fetch these instructions to initialize registers
    for (int i = 0; i < 5; i++) begin
      yarp_seq_item item;
      item = create_instr_fetch(32'h1000 + (i*4), instr_mem[32'h1000 + (i*4)]);
      start_item(item);
      finish_item(item);
    end
  endtask
  
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
  
  // Helper to generate I-type ALU instruction with specific funct3
  virtual function logic [31:0] gen_i_type_alu(logic [2:0] funct3, logic [4:0] rd = 5'd1, 
                                             logic [4:0] rs1 = 5'd0, logic [11:0] imm = 12'h0);
    logic [31:0] instr;
    
    // Create I-type ALU instruction
    instr = {imm, rs1, funct3, rd, 7'h13};
    
    return instr;
  endfunction
  
  // Helper to generate I-type SRAI instruction (special case because it uses funct7[5])
  virtual function logic [31:0] gen_i_type_alu_srai(logic [4:0] rd = 5'd1, 
                                                  logic [4:0] rs1 = 5'd0, 
                                                  logic [4:0] shamt = 5'd0);
    logic [31:0] instr;
    
    // Create SRAI instruction (I-type but with funct7[5]=1)
    instr = {7'b0100000, shamt, rs1, 3'b101, rd, 7'h13};
    
    return instr;
  endfunction
  
endclass
