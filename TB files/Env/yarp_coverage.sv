// YARP Coverage Model - Defines functional coverage for the RISC-V core
class yarp_coverage extends uvm_component;
  // Registration with factory
  `uvm_component_utils(yarp_coverage)
  
  // Analysis export for receiving transactions
  uvm_analysis_imp #(yarp_seq_item, yarp_coverage) item_collected_export;
  
  // Coverage groups
  
  // Instruction type coverage
  covergroup instr_type_cg;
    option.per_instance = 1;
    option.name = "instruction_type_coverage";
    
    // Cover all instruction types
    INSTR_TYPE: coverpoint instr_type {
      bins r_type   = {1};
      bins i_type   = {2};
      bins s_type   = {3};
      bins b_type   = {4};
      bins u_type   = {5};
      bins j_type   = {6};
      illegal_bins illegal = default;
    }
  endgroup
  
  // ALU operation coverage
  covergroup alu_op_cg;
    option.per_instance = 1;
    option.name = "alu_operation_coverage";
    
    // Cover all ALU operations for R-type instructions
    R_FUNCT: coverpoint r_funct {
      bins add  = {4'h0};
      bins sub  = {4'h8};
      bins sll  = {4'h1};
      bins slt  = {4'h2};
      bins sltu = {4'h3};
      bins xor_ = {4'h4};
      bins srl  = {4'h5};
      bins sra  = {4'hd};
      bins or_  = {4'h6};
      bins and_ = {4'h7};
      illegal_bins illegal = default;
    }
    
    // Cover all ALU operations for I-type instructions
    I_FUNCT: coverpoint i_funct {
      bins addi  = {4'h8};
      bins slti  = {4'ha};
      bins sltiu = {4'hb};
      bins xori  = {4'hc};
      bins ori   = {4'he};
      bins andi  = {4'hf};
      bins slli  = {4'h9};
      bins srli  = {4'h5};
      bins srai  = {4'hd};
      illegal_bins illegal = default;
    }
    
    // Cross R and I type operations to ensure all combinations are tested
    R_I_CROSS: cross R_FUNCT, I_FUNCT;
  endgroup
  
  // Branch operation coverage
  covergroup branch_op_cg;
    option.per_instance = 1;
    option.name = "branch_operation_coverage";
    
    // Cover all branch types
    BRANCH_TYPE: coverpoint branch_type {
      bins beq  = {3'h0};
      bins bne  = {3'h1};
      bins blt  = {3'h4};
      bins bge  = {3'h5};
      bins bltu = {3'h6};
      bins bgeu = {3'h7};
      illegal_bins illegal = default;
    }
    
    // Cover branch taken and not taken outcomes
    BRANCH_OUTCOME: coverpoint branch_taken {
      bins taken     = {1};
      bins not_taken = {0};
    }
    
    // Cross branch type and outcome to ensure all combinations are tested
    BRANCH_CROSS: cross BRANCH_TYPE, BRANCH_OUTCOME;
  endgroup
  
  // Memory access coverage
  covergroup mem_access_cg;
    option.per_instance = 1;
    option.name = "memory_access_coverage";
    
    // Cover all memory access types (byte, half-word, word)
    MEM_SIZE: coverpoint mem_size {
      bins byte      = {2'b00};
      bins half_word = {2'b01};
      bins word      = {2'b11};
      illegal_bins illegal = default;
    }
    
    // Cover memory operation (read/write)
    MEM_OP: coverpoint mem_op {
      bins read  = {0};
      bins write = {1};
    }
    
    // Cover address alignment relative to access size
    ALIGNMENT: coverpoint mem_alignment {
      bins aligned     = {0};
      bins unaligned_1 = {1};
      bins unaligned_2 = {2};
      bins unaligned_3 = {3};
    }
    
    // Cross memory size, operation, and alignment
    MEM_CROSS: cross MEM_SIZE, MEM_OP, ALIGNMENT;
  endgroup
  
  // Register usage coverage
  covergroup reg_usage_cg;
    option.per_instance = 1;
    option.name = "register_usage_coverage";
    
    // Cover source register 1 usage
    RS1: coverpoint rs1 {
      // Zero register
      bins zero = {0};
      // Return address register
      bins ra = {1};
      // Stack pointer
      bins sp = {2};
      // Global pointer
      bins gp = {3};
      // Thread pointer
      bins tp = {4};
      // Temporaries
      bins t0_t2 = {5, 6, 7};
      // Saved registers
      bins s0_s1 = {8, 9};
      // Function arguments
      bins a0_a7 = {[10:17]};
      // Saved registers (continued)
      bins s2_s11 = {[18:27]};
      // Temporaries (continued)
      bins t3_t6 = {[28:31]};
    }
    
    // Cover source register 2 usage
    RS2: coverpoint rs2 {
      // Zero register
      bins zero = {0};
      // Return address register
      bins ra = {1};
      // Stack pointer
      bins sp = {2};
      // Global pointer
      bins gp = {3};
      // Thread pointer
      bins tp = {4};
      // Temporaries
      bins t0_t2 = {5, 6, 7};
      // Saved registers
      bins s0_s1 = {8, 9};
      // Function arguments
      bins a0_a7 = {[10:17]};
      // Saved registers (continued)
      bins s2_s11 = {[18:27]};
      // Temporaries (continued)
      bins t3_t6 = {[28:31]};
    }
    
    // Cover destination register usage
    RD: coverpoint rd {
      // Zero register
      bins zero = {0};
      // Return address register
      bins ra = {1};
      // Stack pointer
      bins sp = {2};
      // Global pointer
      bins gp = {3};
      // Thread pointer
      bins tp = {4};
      // Temporaries
      bins t0_t2 = {5, 6, 7};
      // Saved registers
      bins s0_s1 = {8, 9};
      // Function arguments
      bins a0_a7 = {[10:17]};
      // Saved registers (continued)
      bins s2_s11 = {[18:27]};
      // Temporaries (continued)
      bins t3_t6 = {[28:31]};
    }
    
    // Cross source and destination registers
    REG_CROSS: cross RS1, RS2, RD;
  endgroup
  
  // Edge case coverage
  covergroup edge_cases_cg;
    option.per_instance = 1;
    option.name = "edge_case_coverage";
    
    // Cover instruction immediates (focus on edge values)
    IMM_VALUES: coverpoint imm_value {
      bins zero     = {0};
      bins one      = {1};
      bins neg_one  = {-1};
      bins max_pos  = {32'h7FFFFFFF};
      bins max_neg  = {32'h80000000};
      bins random   = default;
    }
    
    // Cover ALU edge cases
    ALU_EDGES: coverpoint alu_edge_case {
      bins overflow_pos = {1};  // Positive overflow
      bins overflow_neg = {2};  // Negative overflow
      bins div_by_zero  = {3};  // Division by zero-like cases
      bins shift_zero   = {4};  // Shift by 0
      bins shift_max    = {5};  // Shift by max value (31)
      bins normal       = {0};  // Normal operation
    }
    
    // Cross ALU operations with edge cases
    ALU_EDGE_CROSS: cross r_funct, ALU_EDGES;
  endgroup
  
  // Data for coverage processing
  protected logic [2:0]  instr_type;    // 1=R, 2=I, 3=S, 4=B, 5=U, 6=J
  protected logic [3:0]  r_funct;       // R-type function (combined funct7[5] and funct3)
  protected logic [3:0]  i_funct;       // I-type function (combined opcode[5] and funct3)
  protected logic [2:0]  branch_type;   // Branch function (funct3)
  protected logic        branch_taken;  // Branch outcome (taken or not)
  protected logic [1:0]  mem_size;      // Memory access size (00=byte, 01=half, 11=word)
  protected logic        mem_op;        // Memory operation (0=read, 1=write)
  protected logic [1:0]  mem_alignment; // Memory address alignment (0=aligned, 1-3=offset)
  protected logic [4:0]  rs1;           // Source register 1
  protected logic [4:0]  rs2;           // Source register 2
  protected logic [4:0]  rd;            // Destination register
  protected logic [31:0] imm_value;     // Immediate value
  protected logic [3:0]  alu_edge_case; // ALU edge case indicator
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    
    // Initialize coverage groups
    instr_type_cg = new();
    alu_op_cg = new();
    branch_op_cg = new();
    mem_access_cg = new();
    reg_usage_cg = new();
    edge_cases_cg = new();
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis export
    item_collected_export = new("item_collected_export", this);
  endfunction
  
  // Write implementation for receiving transactions
  virtual function void write(yarp_seq_item item);
    // Process the transaction for coverage collection
    process_coverage(item);
  endfunction
  
  // Process transaction for coverage collection
  virtual function void process_coverage(yarp_seq_item item);
    // Extract relevant information from transaction
    if (item.tx_type == yarp_seq_item::INSTR_FETCH) begin
      // Set instruction type
      if (item.is_r_type) instr_type = 1;
      else if (item.is_i_type) instr_type = 2;
      else if (item.is_s_type) instr_type = 3;
      else if (item.is_b_type) instr_type = 4;
      else if (item.is_u_type) instr_type = 5;
      else if (item.is_j_type) instr_type = 6;
      else instr_type = 0;
      
      // Extract function fields
      if (item.is_r_type) begin
        // R-type function is {funct7[5], funct3}
        r_funct = {item.funct7[5], item.funct3};
      end
      
      if (item.is_i_type) begin
        // I-type function depends on the specific I-type
        case (item.opcode)
          7'h13: i_funct = {1'b1, item.funct3};  // ALU I-type
          7'h03: i_funct = {1'b0, item.funct3};  // Load I-type
          7'h67: i_funct = 4'h0;                 // JALR
          default: i_funct = 4'h0;
        endcase
      end
      
      if (item.is_b_type) begin
        // Branch type is funct3
        branch_type = item.funct3;
      end
      
      // Extract register usage
      rs1 = item.rs1;
      rs2 = item.rs2;
      rd = item.rd;
      
      // Extract immediate value
      imm_value = item.imm;
      
      // Sample instruction type coverage
      instr_type_cg.sample();
      
      // Sample ALU coverage for R-type and I-type instructions
      if (item.is_r_type || (item.is_i_type && item.opcode == 7'h13)) begin
        alu_op_cg.sample();
      end
      
      // Sample register usage coverage
      reg_usage_cg.sample();
      
      // Analyze for edge cases
      if (item.is_r_type) begin
        // Check for ALU edge cases
        if (item.rs1 == 0 || item.rs2 == 0) alu_edge_case = 3;  // Div-by-zero like
        else if (item.funct3 == 3'b001 || item.funct3 == 3'b101) begin
          // Shift operations
          if (item.rs2 == 0) alu_edge_case = 4;  // Shift by 0
          else if (item.rs2 == 31) alu_edge_case = 5;  // Shift by max
          else alu_edge_case = 0;
        end
        else alu_edge_case = 0;
        
        // Sample edge case coverage
        edge_cases_cg.sample();
      end
    end
    else if (item.tx_type == yarp_seq_item::BRANCH_OUTCOME) begin
      // Record branch outcome
      branch_taken = item.branch_taken;
      
      // Sample branch coverage
      branch_op_cg.sample();
    end
    else if (item.tx_type == yarp_seq_item::DATA_READ || 
             item.tx_type == yarp_seq_item::DATA_WRITE) begin
      // Record memory operation type
      mem_op = (item.tx_type == yarp_seq_item::DATA_WRITE) ? 1 : 0;
      
      // Record memory access size
      mem_size = item.byte_enable;
      
      // Record memory alignment
      mem_alignment = item.address[1:0];
      
      // Sample memory access coverage
      mem_access_cg.sample();
    end
  endfunction
  
  // Report phase - print coverage summary
  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("\n\n=== Coverage Summary ==="), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Instruction Type Coverage: %.2f%%", instr_type_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("ALU Operation Coverage: %.2f%%", alu_op_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Branch Operation Coverage: %.2f%%", branch_op_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Memory Access Coverage: %.2f%%", mem_access_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Register Usage Coverage: %.2f%%", reg_usage_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Edge Case Coverage: %.2f%%", edge_cases_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("\nOverall Coverage: %.2f%%", 
      (instr_type_cg.get_coverage() + 
       alu_op_cg.get_coverage() + 
       branch_op_cg.get_coverage() + 
       mem_access_cg.get_coverage() + 
       reg_usage_cg.get_coverage() + 
       edge_cases_cg.get_coverage()) / 6), UVM_LOW)
  endfunction
  
endclass
