// YARP Sequence Item - Defines transactions for processor testing
class yarp_seq_item extends uvm_sequence_item;
  // Registration with factory
  `uvm_object_utils(yarp_seq_item)
  
  // Transaction types
  typedef enum {
    INSTR_FETCH,    // Instruction fetch transaction
    DATA_READ,      // Data memory read transaction
    DATA_WRITE,     // Data memory write transaction
    REG_WRITE,      // Register write transaction (for monitoring)
    BRANCH_OUTCOME  // Branch outcome transaction (for monitoring)
  } tx_type_e;
  
  // Transaction fields
  rand tx_type_e                tx_type;
  rand logic [31:0]             address;
  rand logic [31:0]             data;
  rand logic [1:0]              byte_enable;
  rand logic [4:0]              reg_addr;     // Register address for register transactions
  rand logic                    branch_taken; // Whether branch was taken or not
  
  // Instruction fields (for instruction fetch transactions)
  rand logic [6:0]              opcode;
  rand logic [2:0]              funct3;
  rand logic [6:0]              funct7;
  rand logic [4:0]              rs1;
  rand logic [4:0]              rs2;
  rand logic [4:0]              rd;
  rand logic [31:0]             imm;
  
  // Instruction encoding (automatically generated from fields)
  logic [31:0]                  encoded_instr;
  
  // Instruction type flags
  logic                         is_r_type;
  logic                         is_i_type;
  logic                         is_s_type;
  logic                         is_b_type;
  logic                         is_u_type;
  logic                         is_j_type;
  
  // Constraints
  constraint valid_opcode_c {
    opcode inside {7'h33, 7'h03, 7'h13, 7'h67, 7'h23, 7'h63, 7'h37, 7'h17, 7'h6F};
  }
  
  constraint valid_byte_enable_c {
    byte_enable inside {2'b00, 2'b01, 2'b11}; // BYTE, HALF_WORD, WORD
  }
  
  constraint valid_register_c {
    rs1 inside {[0:31]};
    rs2 inside {[0:31]};
    rd inside {[0:31]};
    reg_addr inside {[0:31]};
  }
  
  constraint valid_address_alignment_c {
    tx_type == INSTR_FETCH -> (address[1:0] == 2'b00); // Instructions must be word-aligned
    tx_type == DATA_READ || tx_type == DATA_WRITE -> 
      (byte_enable == 2'b00) || // BYTE can be any address
      (byte_enable == 2'b01 && address[0] == 1'b0) || // HALF_WORD must be half-word aligned
      (byte_enable == 2'b11 && address[1:0] == 2'b00); // WORD must be word-aligned
  }
  
  // Constructor
  function new(string name = "yarp_seq_item");
    super.new(name);
  endfunction
  
  // Convert instruction fields to encoded instruction
  function void encode_instruction();
    // Default to all zeros
    encoded_instr = 32'h0;
    
    // Set opcode
    encoded_instr[6:0] = opcode;
    
    // Determine instruction type based on opcode and encode accordingly
    case(opcode)
      7'h33: begin // R-type
        encoded_instr[11:7]  = rd;
        encoded_instr[14:12] = funct3;
        encoded_instr[19:15] = rs1;
        encoded_instr[24:20] = rs2;
        encoded_instr[31:25] = funct7;
        is_r_type = 1'b1;
      end
      
      7'h03, 7'h13, 7'h67: begin // I-type
        encoded_instr[11:7]  = rd;
        encoded_instr[14:12] = funct3;
        encoded_instr[19:15] = rs1;
        encoded_instr[31:20] = imm[11:0];
        is_i_type = 1'b1;
      end
      
      7'h23: begin // S-type
        encoded_instr[11:7]  = imm[4:0];
        encoded_instr[14:12] = funct3;
        encoded_instr[19:15] = rs1;
        encoded_instr[24:20] = rs2;
        encoded_instr[31:25] = imm[11:5];
        is_s_type = 1'b1;
      end
      
      7'h63: begin // B-type
        encoded_instr[7]     = imm[11];
        encoded_instr[11:8]  = imm[4:1];
        encoded_instr[14:12] = funct3;
        encoded_instr[19:15] = rs1;
        encoded_instr[24:20] = rs2;
        encoded_instr[30:25] = imm[10:5];
        encoded_instr[31]    = imm[12];
        is_b_type = 1'b1;
      end
      
      7'h37, 7'h17: begin // U-type
        encoded_instr[11:7]  = rd;
        encoded_instr[31:12] = imm[31:12];
        is_u_type = 1'b1;
      end
      
      7'h6F: begin // J-type
        encoded_instr[11:7]  = rd;
        encoded_instr[19:12] = imm[19:12];
        encoded_instr[20]    = imm[11];
        encoded_instr[30:21] = imm[10:1];
        encoded_instr[31]    = imm[20];
        is_j_type = 1'b1;
      end
    endcase
  endfunction
  
  // Decode encoded instruction to fields
  function void decode_instruction(logic [31:0] instr);
    // Store the encoded instruction
    encoded_instr = instr;
    
    // Extract basic fields
    opcode = instr[6:0];
    funct3 = instr[14:12];
    rd     = instr[11:7];
    rs1    = instr[19:15];
    rs2    = instr[24:20];
    funct7 = instr[31:25];
    
    // Reset type flags
    is_r_type = 1'b0;
    is_i_type = 1'b0;
    is_s_type = 1'b0;
    is_b_type = 1'b0;
    is_u_type = 1'b0;
    is_j_type = 1'b0;
    
    // Determine instruction type and extract immediate
    case(opcode)
      7'h33: begin // R-type
        imm = 32'h0; // R-type instructions don't have immediate
        is_r_type = 1'b1;
      end
      
      7'h03, 7'h13, 7'h67: begin // I-type
        imm = {{20{instr[31]}}, instr[31:20]};
        is_i_type = 1'b1;
      end
      
      7'h23: begin // S-type
        imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        is_s_type = 1'b1;
      end
      
      7'h63: begin // B-type
        imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        is_b_type = 1'b1;
      end
      
      7'h37, 7'h17: begin // U-type
        imm = {instr[31:12], 12'h0};
        is_u_type = 1'b1;
      end
      
      7'h6F: begin // J-type
        imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        is_j_type = 1'b1;
      end
    endcase
  endfunction
  
  // UVM convert2string method for debugging
  virtual function string convert2string();
    string s;
    s = $sformatf("tx_type=%s, ", tx_type.name());
    
    case(tx_type)
      INSTR_FETCH: begin
        string instr_type = "";
        if(is_r_type) instr_type = "R-type";
        else if(is_i_type) instr_type = "I-type";
        else if(is_s_type) instr_type = "S-type";
        else if(is_b_type) instr_type = "B-type";
        else if(is_u_type) instr_type = "U-type";
        else if(is_j_type) instr_type = "J-type";
        
        s = {s, $sformatf("addr=0x%0h, instr=0x%0h, type=%s, opcode=0x%0h, rs1=%0d, rs2=%0d, rd=%0d",
                         address, encoded_instr, instr_type, opcode, rs1, rs2, rd)};
      end
      
      DATA_READ: begin
        s = {s, $sformatf("addr=0x%0h, data=0x%0h, byte_en=%0b", address, data, byte_enable)};
      end
      
      DATA_WRITE: begin
        s = {s, $sformatf("addr=0x%0h, data=0x%0h, byte_en=%0b", address, data, byte_enable)};
      end
      
      REG_WRITE: begin
        s = {s, $sformatf("reg_addr=%0d, data=0x%0h", reg_addr, data)};
      end
      
      BRANCH_OUTCOME: begin
        s = {s, $sformatf("branch_taken=%0b", branch_taken)};
      end
    endcase
    
    return s;
  endfunction
  
  // Deep copy method for UVM
  virtual function void do_copy(uvm_object rhs);
    yarp_seq_item rhs_cast;
    if(!$cast(rhs_cast, rhs)) begin
      `uvm_error("do_copy", "Cast failed in do_copy")
      return;
    end
    super.do_copy(rhs);
    
    tx_type = rhs_cast.tx_type;
    address = rhs_cast.address;
    data = rhs_cast.data;
    byte_enable = rhs_cast.byte_enable;
    reg_addr = rhs_cast.reg_addr;
    branch_taken = rhs_cast.branch_taken;
    
    opcode = rhs_cast.opcode;
    funct3 = rhs_cast.funct3;
    funct7 = rhs_cast.funct7;
    rs1 = rhs_cast.rs1;
    rs2 = rhs_cast.rs2;
    rd = rhs_cast.rd;
    imm = rhs_cast.imm;
    
    encoded_instr = rhs_cast.encoded_instr;
    is_r_type = rhs_cast.is_r_type;
    is_i_type = rhs_cast.is_i_type;
    is_s_type = rhs_cast.is_s_type;
    is_b_type = rhs_cast.is_b_type;
    is_u_type = rhs_cast.is_u_type;
    is_j_type = rhs_cast.is_j_type;
  endfunction
  
endclass
