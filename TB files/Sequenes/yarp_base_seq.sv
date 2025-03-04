// YARP Base Sequence - Common functionality for all sequences
class yarp_base_seq extends uvm_sequence #(yarp_seq_item);
  // Registration with factory
  `uvm_object_utils(yarp_base_seq)
  
  // Properties
  int unsigned min_instr_count = 10;  // Minimum number of instructions to generate
  int unsigned max_instr_count = 100; // Maximum number of instructions to generate
  int unsigned instr_count;           // Actual number of instructions to generate
  
  // Memory model for the reference model
  protected logic [31:0] instr_mem[logic [31:0]];
  protected logic [31:0] data_mem[logic [31:0]];
  
  // Constructor
  function new(string name = "yarp_base_seq");
    super.new(name);
  endfunction
  
  // Pre-body function - called before body()
  virtual task pre_body();
    if (starting_phase != null) begin
      starting_phase.raise_objection(this, "Starting sequence");
    end
    
    // Randomize instruction count unless already set
    if (instr_count == 0) begin
      instr_count = $urandom_range(min_instr_count, max_instr_count);
    end
    
    `uvm_info(get_type_name(), $sformatf("Generating sequence with %0d instructions", instr_count), UVM_MEDIUM)
    
    // Initialize memories
    initialize_memories();
  endtask
  
  // Post-body function - called after body()
  virtual task post_body();
    if (starting_phase != null) begin
      starting_phase.drop_objection(this, "Completed sequence");
    end
  endtask
  
  // Initialize instruction and data memories
  virtual function void initialize_memories();
    // Clear memories
    instr_mem.delete();
    data_mem.delete();
    
    // Add a default trap instruction at address 0
    instr_mem[32'h0] = 32'h00000013;  // NOP (addi x0, x0, 0)
  endfunction
  
  // Helper function to create instruction fetch transaction
  virtual function yarp_seq_item create_instr_fetch(logic [31:0] addr, logic [31:0] instr);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    item.tx_type = yarp_seq_item::INSTR_FETCH;
    item.address = addr;
    item.data = instr;
    item.decode_instruction(instr);
    return item;
  endfunction
  
  // Helper function to create data read transaction
  virtual function yarp_seq_item create_data_read(logic [31:0] addr, logic [31:0] data, logic [1:0] byte_en);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    item.tx_type = yarp_seq_item::DATA_READ;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    return item;
  endfunction
  
  // Helper function to create data write transaction
  virtual function yarp_seq_item create_data_write(logic [31:0] addr, logic [31:0] data, logic [1:0] byte_en);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    item.tx_type = yarp_seq_item::DATA_WRITE;
    item.address = addr;
    item.data = data;
    item.byte_enable = byte_en;
    return item;
  endfunction
  
  // Helper function to create register write transaction
  virtual function yarp_seq_item create_reg_write(logic [4:0] reg_addr, logic [31:0] data);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    item.tx_type = yarp_seq_item::REG_WRITE;
    item.reg_addr = reg_addr;
    item.data = data;
    return item;
  endfunction
  
  // Helper function to create branch outcome transaction
  virtual function yarp_seq_item create_branch_outcome(logic taken);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    item.tx_type = yarp_seq_item::BRANCH_OUTCOME;
    item.branch_taken = taken;
    return item;
  endfunction
  
  // Helper function to generate a random R-type instruction
  virtual function logic [31:0] gen_r_type_instr(logic [4:0] rd = 0, logic [4:0] rs1 = 0, logic [4:0] rs2 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == 7'h33;  // R-type opcode
      if (rd != 0) this.rd == rd;
      if (rs1 != 0) this.rs1 == rs1;
      if (rs2 != 0) this.rs2 == rs2;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
  // Helper function to generate a random I-type instruction
  virtual function logic [31:0] gen_i_type_instr(logic [2:0] i_type = 3'b000, logic [4:0] rd = 0, logic [4:0] rs1 = 0, logic [11:0] imm12 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    logic [6:0] op;
    
    // Determine opcode based on I-type subtype
    case(i_type)
      3'b000: op = 7'h13;  // I-type ALU
      3'b001: op = 7'h03;  // I-type load
      3'b010: op = 7'h67;  // JALR
      default: op = 7'h13;
    endcase
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == op;
      if (rd != 0) this.rd == rd;
      if (rs1 != 0) this.rs1 == rs1;
      if (imm12 != 0) this.imm[11:0] == imm12;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
  // Helper function to generate a random S-type instruction
  virtual function logic [31:0] gen_s_type_instr(logic [4:0] rs1 = 0, logic [4:0] rs2 = 0, logic [11:0] imm12 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == 7'h23;  // S-type opcode
      if (rs1 != 0) this.rs1 == rs1;
      if (rs2 != 0) this.rs2 == rs2;
      if (imm12 != 0) this.imm[11:0] == imm12;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
  // Helper function to generate a random B-type instruction
  virtual function logic [31:0] gen_b_type_instr(logic [4:0] rs1 = 0, logic [4:0] rs2 = 0, logic [12:0] imm13 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == 7'h63;  // B-type opcode
      if (rs1 != 0) this.rs1 == rs1;
      if (rs2 != 0) this.rs2 == rs2;
      if (imm13 != 0) this.imm[12:0] == imm13;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
  // Helper function to generate a random U-type instruction
  virtual function logic [31:0] gen_u_type_instr(logic u_type = 1'b0, logic [4:0] rd = 0, logic [19:0] imm20 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    logic [6:0] op;
    
    // Determine opcode based on U-type subtype
    op = u_type ? 7'h17 : 7'h37;  // AUIPC or LUI
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == op;
      if (rd != 0) this.rd == rd;
      if (imm20 != 0) this.imm[31:12] == imm20;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
  // Helper function to generate a random J-type instruction
  virtual function logic [31:0] gen_j_type_instr(logic [4:0] rd = 0, logic [20:0] imm21 = 0);
    yarp_seq_item item = yarp_seq_item::type_id::create("item");
    logic [31:0] instr;
    
    // Randomize instruction fields
    assert(item.randomize() with {
      opcode == 7'h6F;  // J-type opcode
      if (rd != 0) this.rd == rd;
      if (imm21 != 0) this.imm[20:0] == imm21;
    });
    
    // Encode the instruction
    item.encode_instruction();
    instr = item.encoded_instr;
    
    return instr;
  endfunction
  
endclass
