`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ALU
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: ALU unit of RISCV CPU
//////////////////////////////////////////////////////////////////////////////////

//���ܺͽӿ�˵��
	//ALU��������������������AluContrl�Ĳ�ͬ�����в�ͬ�ļ���������������������AluOut
	//AluContrl�����Ͷ�����Parameters.v��
//�Ƽ���ʽ��
    //case()
    //    `ADD:        AluOut<=Operand1 + Operand2; 
    //   	.......
    //    default:    AluOut <= 32'hxxxxxxxx;                          
    //endcase
//ʵ��Ҫ��  
    //��ȫģ��

`include "Parameters.v"   
module ALU(
    input wire [31:0] Operand1,
    input wire [31:0] Operand2,
    input wire [3:0] AluContrl,
    output reg [31:0] AluOut
    );    
    always @(*) 
    begin
    case (AluContrl)
        `ADD: AluOut <= Operand1 + Operand2;
        `SUB: AluOut <= Operand1 - Operand2;
        `SLL: AluOut <= Operand1 << Operand2[4: 0];
        `SRL: AluOut <= Operand1 >> Operand2[4: 0];
        `SRA: AluOut <= $signed(Operand1) >>> Operand2[4: 0];
        `XOR: AluOut <= Operand1 ^ Operand2;
        `OR: AluOut <= Operand1 | Operand2;
        `AND: AluOut <= Operand1 & Operand2;
        `SLT: AluOut <= ($signed(Operand1) < $signed(Operand2)) ? 32'h1 : 32'h0;
        `SLTU: AluOut <= (Operand1 < Operand2) ? 32'h1 : 32'h0;
        `LUI: AluOut <= (Operand2) & 32'hfffff000;
        default: AluOut <= 32'hxxxxxxxx;
    endcase
end
    // �벹ȫ�˴�����

endmodule

