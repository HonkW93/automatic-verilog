`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/01/11 15:53:54
// Design Name: 
// Module Name: execute
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "macros.v"

module execute(
input wire                  clk,
input wire                  rst,
input wire [3:0]            ctr_ex,
input wire [5:0]            ctr_m,
input wire [1:0]            ctr_wb,
input wire [31:0]           pc,
input wire [31:0]           instruction,
input wire [31:0]           reg1_data,
input wire [31:0]           reg2_data,
input wire signed [31:0]    immediate,
input wire [4:0]            rt,
input wire [4:0]            rd,
input wire                  isFlush,
input wire                  isCacheStall,
input [3:0]                 ALUcmd,
output reg [31:0]           reg_ALU_out,
output reg [31:0]           reg_reg2_data,
output reg [4:0]            reg_write_reg,
output reg [5:0]            reg_ctr_m,
output reg [1:0]            reg_ctr_wb,
/* bypass interface */
input wire [31:0]           ex_mem_data,
input wire [31:0]           mem_wb_data,
input wire [1:0]            forward_a,
input wire [1:0]            forward_b,
output wire [4:0]           ex_write_reg,
output wire                 ex_regwrite_flag,
input wire [1:0]            bht_token,
output reg [1:0]            reg_bht_token,
output reg signed [31:0]    reg_pc,
output reg signed [31:0]    reg_pc_branch,
output reg signed [31:0]    reg_pc_jump,
output reg signed [31:0]    reg_pc_next
    );
    
       /* ALU related signals */
      wire                  ALUSrc_flag;
      wire [31:0]           ALU_out;
      wire                  regdst_flag;
      
      wire [31:0]           ALU_opa;
      wire [31:0]           ALU_opb;
      wire [31:0]           ALU_opb2;
      wire signed [31:0]    pc_next;
      
      assign pc_next = reg_pc + 3'd4;
      
      /* the write reg */
      assign regdst_flag = ctr_ex[3];
      /* pass on the bypass related signal to the ID stage */
      assign ex_write_reg = (regdst_flag) ? rd : rt;
      assign ex_regwrite_flag = ctr_wb[1];
      assign ALUSrc_flag = ctr_ex[0];
      
      /* the bypath for the OPA */
      bypath bypath_inst_opa(
        .reg_data(      reg1_data       ),
        .ex_mem_data(   ex_mem_data     ),
        .mem_wb_data(   mem_wb_data     ),
        .sel(           forward_a       ),
        .out(           ALU_opa         )
      );
      
      /* the bypath for the OPB */
      bypath bypath_inst_opb(
        .reg_data(      reg2_data       ),
        .ex_mem_data(   ex_mem_data     ),
        .mem_wb_data(   mem_wb_data     ),
        .sel(           forward_b       ),
        .out(           ALU_opb         )
      );
      
      /* the bypath for the OPB */
      bypath2 bypath2_inst(
        .reg_data(      reg2_data       ),
        .ex_mem_data(   ex_mem_data     ),
        .mem_wb_data(   mem_wb_data     ),
        .immediate(     immediate       ),
        .ALUSrc_flag(   ALUSrc_flag     ),
        .sel(           forward_b       ),
        .out(           ALU_opb2         )
      );
      
      /* pass on the cpntrol signals to next stage */
      always @(posedge clk)
      begin
        if( rst )
        begin
            reg_ctr_m <= 0;
            reg_ctr_wb <= 0;
            reg_bht_token <= 0;
            reg_pc <= 0;
            reg_ALU_out <= 0;
            reg_reg2_data <= 0;
            reg_write_reg <= 0;
            reg_pc_branch <= 0;
            reg_pc_next <= 0;
            reg_pc_jump <= 0;
        end
        else
        begin
            /* clear the control signals when found FLUSH signal */
            if( isCacheStall )
            begin
                reg_ctr_m <= reg_ctr_m;
                reg_ctr_wb <= reg_ctr_wb;
                reg_bht_token <= reg_bht_token;
                reg_pc <= reg_pc;
                reg_ALU_out <= reg_ALU_out;
                reg_reg2_data <= reg_reg2_data;
                reg_write_reg <= reg_write_reg;
                reg_pc_branch <= reg_pc_branch;
                reg_pc_next <= reg_pc_next;
                reg_pc_jump <= reg_pc_jump;
            end
            else if( isFlush )
            begin
                reg_ctr_m <= 0;
                reg_ctr_wb <= 0;
                reg_bht_token <= 0;
                reg_pc <= 0;
                reg_ALU_out <= 0;
                reg_reg2_data <= 0;
                reg_write_reg <= 0;
                reg_pc_branch <= 0;
                reg_pc_next <= 0;
                reg_pc_jump <= 0;
            end
            else
            begin
                reg_ctr_m <= ctr_m;
                reg_ctr_wb <= ctr_wb;
                reg_bht_token <= bht_token;
                reg_pc <= pc;
                reg_ALU_out <= ALU_out;
                reg_reg2_data <= ALU_opb;
                reg_write_reg <= ex_write_reg;
                reg_pc_branch <= pc_next + (immediate << 2);
                reg_pc_next <= pc_next;
                if( ctr_m[5:4] == `JUMP_J || ctr_m[5:4] == `JUMP_JAL )
                    reg_pc_jump <= {pc_next[31:28], instruction[25:0], 2'b00};
                else if( ctr_m[5:4] == `JUMP_JR  )
                      reg_pc_jump <= ALU_opa;
                else
                    reg_pc_jump <= 0;
            end
        end
      end
     

//Instantiate of the ALU 	 
    ALU ALU_inst (
        .opa(			ALU_opa			    ), 
        .opb(			ALU_opb2			), 
        .cmd(			ALUcmd				), 
        .res(			ALU_out				)
    );
    
endmodule
