`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2021 14:04:40
// Design Name: 
// Module Name: forw_unit
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


module forw_unit(
   input  wire [4:0] mem_reg_rd,
   input  wire [4:0] wb_reg_rd,
   input  wire       mem_reg_write,
   input  wire       wb_reg_write,
   input  wire [4:0] exe_reg_rs,
   input  wire [4:0] exe_reg_rt,
   output reg       forw_operand_rs,
   output reg       forw_operand_rt,
   output reg       forw_operand_rs_wb_mem,
   output reg       forw_operand_rt_wb_mem

   );
   

   
    always@(*) begin
        if ((mem_reg_write) || (wb_reg_write))begin
            if ((mem_reg_rd != 0) || (wb_reg_rd != 0))begin
                if(mem_reg_rd == exe_reg_rs)begin
                    forw_operand_rs <= 1'b1;
                    forw_operand_rs_wb_mem <= 1'b1;
                end else if (exe_reg_rs == wb_reg_rd)begin
                    forw_operand_rs <= 1'b0;
                    forw_operand_rs_wb_mem <= 1'b1;
                end else begin
                    forw_operand_rs <= 1'b0;
                    forw_operand_rs_wb_mem <= 1'b0;                    
                end
                if (mem_reg_rd == exe_reg_rt) begin
                    forw_operand_rt <= 1'b1;
                    forw_operand_rt_wb_mem <= 1'b1;
                end else if(exe_reg_rt == wb_reg_rd)begin
                    forw_operand_rt <= 1'b0;
                    forw_operand_rt_wb_mem <= 1'b1;                    
                end else begin
                    forw_operand_rt <= 1'b0;
                    forw_operand_rt_wb_mem <= 1'b0;
                end
            end
        end
    end                               
endmodule
