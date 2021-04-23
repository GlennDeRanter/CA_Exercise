//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] if_branch_pc,if_updated_pc,current_pc,if_jump_pc,
                  id_branch_pc, id_updated_pc, id_jump_pc,instruction,
                  id_instruction, exe_instruction, 
                  mem_instruction, wb_instruction,
                  forw_operand_rs, forw_operand_rt,
                  alu_operand_0, alu_operand_2_non_forw;
wire [       1:0] if_alu_op, id_alu_op, exe_alu_op;
wire [       3:0] alu_control;
wire              if_reg_dst,branch,if_mem_read,if_mem_2_reg,
                  if_mem_write,if_alu_src, if_reg_write, jump,
                  id_reg_dst,id_mem_read,id_mem_2_reg,
                  id_mem_write,id_alu_src, id_reg_write, 
                  exe_reg_dst,exe_mem_read,exe_mem_2_reg,
                  exe_mem_write,exe_alu_src, exe_reg_write, 
                  mem_reg_dst,mem_mem_read,mem_mem_2_reg,
                  mem_mem_write, mem_reg_write,
                  wb_reg_dst,wb_mem_2_reg, 
                  forw_operand_rs_mux_mem, forw_operand_rt_mux_mem,
                  forw_operand_rs_mux_wb, forw_operand_rt_mux_wb,
                  wb_reg_write;
wire [       4:0] regfile_waddr, mem_reg_rd;
wire [      31:0] regfile_wdata, mem_dram_data, wb_dram_data,
                  exe_alu_out, mem_alu_out, wb_alu_out,
                  id_regfile_data_1,id_regfile_data_2,
                  exe_regfile_data_1,exe_regfile_data_2,
                  mem_regfile_data_2, alu_operand_2;

wire signed [31:0] id_immediate_extended, exe_immediate_extended;

assign id_immediate_extended = $signed(id_instruction[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (id_branch_pc ),
   .jump_pc   (id_jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(if_updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

control_unit control_unit(
   .opcode   (instruction[31:26]),
   .reg_dst  (if_reg_dst           ),
   .branch   (branch            ),
   .mem_read (if_mem_read          ),
   .mem_2_reg(if_mem_2_reg         ),
   .alu_op   (if_alu_op            ),
   .mem_write(if_mem_write         ),
   .alu_src  (if_alu_src           ),
   .reg_write(if_reg_write         ),
   .jump     (jump              )
);

reg_arstn_en #(
      .DATA_W(8)
) signal_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({if_alu_op, if_alu_src, if_mem_write, if_mem_read, if_reg_write, if_mem_2_reg, if_reg_dst}),
      .en    (enable    ),
      .dout  ({id_alu_op, id_alu_src, id_mem_write, id_mem_read, id_reg_write, id_mem_2_reg, id_reg_dst})
   );

reg_arstn_en #(
      .DATA_W(128)
) data_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({instruction, if_updated_pc, if_branch_pc, if_jump_pc} ),
      .en    (enable    ),
      .dout  ({id_instruction, id_updated_pc, id_branch_pc, id_jump_pc})
);   


branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (id_updated_pc        ),
   .instruction  (id_instruction       ),
   .branch_offset(id_immediate_extended),
   .branch_pc    (id_branch_pc         ),
   .jump_pc      (id_jump_pc         )
);


register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(wb_reg_write         ),
   .raddr_1  (id_instruction[25:21]),
   .raddr_2  (id_instruction[20:16]),
   .waddr    (regfile_waddr     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (id_regfile_data_1    ),
   .rdata_2  (id_regfile_data_2    )
);


reg_arstn_en #(
      .DATA_W(8)
) signal_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({id_alu_op, id_alu_src, id_mem_write, id_mem_read, id_reg_write, id_mem_2_reg, id_reg_dst}  ),
      .en    (enable    ),
      .dout  ({exe_alu_op, exe_alu_src, exe_mem_write, exe_mem_read, exe_reg_write, exe_mem_2_reg, exe_reg_dst})
); 

reg_arstn_en #(
      .DATA_W(128)
) data_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({id_instruction, id_immediate_extended, id_regfile_data_1, id_regfile_data_2}),
      .en    (enable    ),
      .dout  ({exe_instruction, exe_immediate_extended, exe_regfile_data_1, exe_regfile_data_2})
); 

alu_control alu_ctrl(
   .function_field (exe_instruction[5:0]),
   .alu_op         (exe_alu_op          ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux_in_1 (
   .input_a (exe_immediate_extended),
   .input_b (exe_regfile_data_2    ),
   .select_a(exe_alu_src           ),
   .mux_out (alu_operand_2_non_forw     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux_forw_value_in0 (
   .input_a (mem_alu_out),
   .input_b (regfile_wdata ),
   .select_a(forw_operand_rs_mux_mem),
   .mux_out (forw_operand_rs     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux_forw_value_in1 (
   .input_a (mem_alu_out),
   .input_b (regfile_wdata   ),
   .select_a(forw_operand_rt_mux_mem           ),
   .mux_out (forw_operand_rt     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux_forw_in0 (
   .input_a (forw_operand_rs),
   .input_b (exe_regfile_data_1   ),
   .select_a(forw_operand_rs_mux_wb          ),
   .mux_out (alu_operand_0     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux_forw_in1 (
   .input_a (forw_operand_rt),
   .input_b (alu_operand_2_non_forw    ),
   .select_a(forw_operand_rt_mux_wb          ),
   .mux_out (alu_operand_2     )
);

alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (alu_operand_0),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (exe_alu_out       ),
   .shft_amnt(exe_instruction[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

reg_arstn_en #(
      .DATA_W(5)
) signal_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({exe_mem_write, exe_mem_read, exe_reg_write, exe_mem_2_reg, exe_reg_dst}  ),
      .en    (enable    ),
      .dout  ({mem_mem_write, mem_mem_read, mem_reg_write, mem_mem_2_reg, mem_reg_dst})
); 

reg_arstn_en #(
      .DATA_W(96)
) data_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({exe_instruction, exe_regfile_data_2, exe_alu_out}),
      .en    (enable    ),
      .dout  ({mem_instruction, mem_regfile_data_2, mem_alu_out})
); 


sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (mem_alu_out       ),
   .wen      (mem_mem_write     ),
   .ren      (mem_mem_read      ),
   .wdata    (mem_regfile_data_2),
   .rdata    (mem_dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);

reg_arstn_en #(
      .DATA_W(3)
) signal_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({mem_reg_write, mem_mem_2_reg, mem_reg_dst}),
      .en    (enable    ),
      .dout  ({wb_reg_write, wb_mem_2_reg, wb_reg_dst})
); 

reg_arstn_en #(
      .DATA_W(96)
) data_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   ({mem_instruction, mem_dram_data, mem_alu_out}),
      .en    (enable    ),
      .dout  ({wb_instruction, wb_dram_data, wb_alu_out})
); 

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (wb_dram_data    ),
   .input_b  (wb_alu_out      ),
   .select_a (wb_mem_2_reg     ),
   .mux_out  (regfile_wdata)
);





mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (wb_instruction[15:11]),
   .input_b (wb_instruction[20:16]),
   .select_a(wb_reg_dst          ),
   .mux_out (regfile_waddr     )
);

mux_2 #(
   .DATA_W(5)
) forw_unit_rd_mux (
   .input_a (mem_instruction[15:11]),
   .input_b (mem_instruction[20:16]),
   .select_a(mem_reg_dst          ),
   .mux_out (mem_reg_rd    )
);

forw_unit forwarding_unit(
  .mem_reg_rd(mem_reg_rd),
  .wb_reg_rd(regfile_waddr),
  .mem_reg_write(mem_reg_write),
  .wb_reg_write(wb_reg_write),
  .exe_reg_rs(exe_instruction[25:21]),
  .exe_reg_rt(exe_instruction[20:16]),
  .forw_operand_rs(forw_operand_rs_mux_mem),
  .forw_operand_rt(forw_operand_rt_mux_mem),
  .forw_operand_rs_wb_mem(forw_operand_rs_mux_wb),
  .forw_operand_rt_wb_mem(forw_operand_rt_mux_wb)
  );
   
   
   
   
   
endmodule


