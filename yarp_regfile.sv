// --------------------------------------------------------
// Register File
// --------------------------------------------------------

module yarp_regfile (
  input   logic          clk,
  input   logic          reset_n,

  // Source registers
  input   logic [4:0]    rs1_addr_i,
  input   logic [4:0]    rs2_addr_i,

  // Destination register
  input   logic [4:0]    rd_addr_i,
  input   logic          wr_en_i,
  input   logic [31:0]   wr_data_i,

  // Register Data
  output  logic [31:0]   rs1_data_o,
  output  logic [31:0]   rs2_data_o
);


  // Implement register file as an 2D array
 
  logic [31:0] [31:0] regfile;

  //create a generate for loop for the 32 registers 
  for (genvar i = 0; i < 32; i++) begin : gen_wr_en
  	logic reg_wr_en;
    
    assign reg_wr_en = (rd_addr_i == i[4:0]) & wr_en_i;
    //now check enable signal and write into the rd reg
    
    always_ff @(posedge clk) begin
      if (i == 0) begin
        regfile[i] <= 32'h0;
      end
      else begin
        if (reg_wr_en) begin
          regfile[i] <= wr_data_i;
        end
      end
    end
  end
  
  assign rs1_data_o = regfile[rs1_addr_i];
  assign rs2_data_o = regfile[rs2_addr_i];

endmodule