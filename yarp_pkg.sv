package yarp_pkg;

  typedef enum logic[6:0] {
    R_TYPE    = 7'h33,
    I_TYPE_0  = 7'h03,
    I_TYPE_1  = 7'h13,
    I_TYPE_2  = 7'h67,
    S_TYPE    = 7'h23,
    B_TYPE    = 7'h63,
    U_TYPE_0  = 7'h37,
    U_TYPE_1  = 7'h17,
    J_TYPE    = 7'h6F
  } riscv_op_t;

  typedef enum logic[3:0] {
    OP_ADD,
    OP_SUB,
    OP_SLL,
    OP_SRL,
    OP_SRA,
    OP_OR,
    OP_AND,
    OP_XOR,
    OP_SLTU,
    OP_SLT
  } alu_op_t;

endpackage