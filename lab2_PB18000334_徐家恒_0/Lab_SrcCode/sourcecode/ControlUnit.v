`timescale 1ns / 1ps 
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Wu Yuzhang
//
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说�??
//ControlUnit       是本CPU的指令译码器，组合�?�辑电路
//输入
// Op               是指令的操作码部�??
// Fn3              是指令的func3部分
// Fn7              是指令的func7部分
//输出
// JalD==1          表示Jal指令到达ID译码阶段
// JalrD==1         表示Jalr指令到达ID译码阶段
// RegWriteD        表示ID阶段的指令对应的寄存器写入模�??
// MemToRegD==1     表示ID阶段的指令需要将data memory读取的�?�写入寄存器,
// MemWriteD        �??4bit，采用独热码格式，对于data memory�??32bit字按byte进行写入,MemWriteD=0001表示只写入最�??1个byte，和xilinx bram的接口类�??
// LoadNpcD==1      表示将NextPC输出到ResultM
// RegReadD         表示A1和A2对应的寄存器值是否被使用到了，用于forward的处�??
// BranchTypeD      表示不同的分支类型，�??有类型定义在Parameters.v�??
// AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v�??
// AluSrc2D         表示Alu输入�??2的�?�择
// AluSrc1D         表示Alu输入�??1的�?�择
// ImmType          表示指令的立即数格式
//实验要求
//补全模块

`include "Parameters.v"
module ControlUnit(
           input wire [6: 0] Op,
           input wire [2: 0] Fn3,
           input wire [6: 0] Fn7,
           output wire JalD,
           output wire JalrD,
           output reg [2: 0] RegWriteD,
           output wire MemToRegD,
           output reg [3: 0] MemWriteD,
           output wire LoadNpcD,
           output reg [1: 0] RegReadD,
           output reg [2: 0] BranchTypeD,
           output reg [3: 0] AluContrlD,
           output wire [1: 0] AluSrc2D,
           output wire AluSrc1D,
           output reg [2: 0] ImmType
       );

assign LoadNpcD = JalD | JalrD ;
assign JalD = (Op == 7'b1101111) ? 1'b1 : 1'b0;
assign JalrD = (Op == 7'b1100111) ? 1'b1 : 1'b0;
assign MemToRegD = (Op == 7'b0000011) ? 1'b1 : 1'b0;
assign AluSrc1D = (Op == 7'b0010111) ? 1'b1 : 1'b0;

reg [1: 0] AluSrc2DReg;
assign AluSrc2D = AluSrc2DReg;
always@(*) 
begin
    if ((Op == 7'b0010011) && (Fn3[1: 0] == 2'b01))
        AluSrc2DReg <= 2'b01;
    else if ( (Op == 7'b0110011) || (Op == 7'b1100011) )
        AluSrc2DReg <= 2'b00 ;
    else
        AluSrc2DReg <= 2'b10;
end
always@(*) 
begin
    case (ImmType)
        `RTYPE: RegReadD = 2'b11;
        `ITYPE: RegReadD = 2'b10;
        `STYPE: RegReadD = 2'b11;
        `BTYPE: RegReadD = 2'b11;
        `UTYPE: RegReadD = 2'b00;
        `JTYPE: RegReadD = 2'b00;
        default: RegReadD = 2'b00;
    endcase
end
always @(* ) begin
    if (Op == 7'b1100011)
    begin
        case (Fn3)
            3'b000: BranchTypeD <= `BEQ;
            3'b001: BranchTypeD <= `BNE;
            3'b100: BranchTypeD <= `BLT;
            3'b101: BranchTypeD <= `BGE;
            3'b110: BranchTypeD <= `BLTU;
            default: BranchTypeD <= `BGEU;
        endcase
    end
    else
        BranchTypeD <= `NOBRANCH;
end
always@( * )
case (Op)
    7'b001_0011:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        ImmType <= `ITYPE;
        case (Fn3)
            3'b000: AluContrlD <= `ADD;  //ADDI
            3'b001: AluContrlD <= `SLL;  //SLLI
            3'b010: AluContrlD <= `SLT;  //SLTI
            3'b011: AluContrlD <= `SLTU;   //SLTIU
            3'b100: AluContrlD <= `XOR;    //XORI
            3'b101:
                if (Fn7[5] == 1) AluContrlD <= `SRA;   //SRAI
                else AluContrlD <= `SRL;   //SRLI
            3'b110: AluContrlD <= `OR;   //ORI
            default: AluContrlD <= `AND;    //ANDI
        endcase
    end
    7'b011_0011:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        ImmType <= `RTYPE;
        case (Fn3)
            3'b000:
            begin
                if (Fn7[5] == 1) AluContrlD <= `SUB;   //SUB
                else AluContrlD <= `ADD;   //ADD
            end
            3'b001: AluContrlD <= `SLL;    //SLL
            3'b010: AluContrlD <= `SLT;    //SLT
            3'b011: AluContrlD <= `SLTU;    //SLTU
            3'b100: AluContrlD <= `XOR;    //XOR
            3'b101:
                if (Fn7[5] == 1) AluContrlD <= `SRA;   //SRA
                else AluContrlD <= `SRL;   //SRL
            3'b110: AluContrlD <= `OR;    //OR
            default: AluContrlD <= `AND;    //AND
        endcase
    end
    7'b000_0011:
    begin
        MemWriteD <= 4'b0000;
        AluContrlD <= `ADD;
        ImmType <= `ITYPE;
        case (Fn3)
            3'b000: RegWriteD <= `LB;    //LB
            3'b001: RegWriteD <= `LH;    //LH
            3'b010: RegWriteD <= `LW;    //LW
            3'b100: RegWriteD <= `LBU;    //LBU
            default: RegWriteD <= `LHU;    //LHU
        endcase
    end
    7'b010_0011:
    begin
        RegWriteD <= `NOREGWRITE;
        AluContrlD <= `ADD;
        ImmType <= `STYPE;
        case (Fn3)
            3'b000: MemWriteD <= 4'b0001;    //SB
            3'b001: MemWriteD <= 4'b0011;    //SH
            default: MemWriteD <= 4'b1111;   //SW
        endcase
    end
    7'b011_0111:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        AluContrlD <= `LUI;
        ImmType <= `UTYPE;    //LUI
    end
    7'b001_0111:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        AluContrlD <= `ADD;
        ImmType <= `UTYPE;    //AUIPC
    end
    7'b110_1111:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        AluContrlD <= `ADD;
        ImmType <= `JTYPE;    //JAL
    end
    7'b110_0111:
    begin
        RegWriteD <= `LW;
        MemWriteD <= 4'b0000;
        AluContrlD <= `ADD;
        ImmType <= `ITYPE;    //JALR
    end
    7'b110_0011:
    begin
        RegWriteD <= `NOREGWRITE;
        MemWriteD <= 4'b0000;
        ImmType <= `BTYPE;
        AluContrlD <= `ADD;    //BRANCH
    end
    default:
    begin
        RegWriteD <= `NOREGWRITE;
        MemWriteD <= 4'b0000;
        AluContrlD <= `ADD;
        ImmType <= `ITYPE;
    end
endcase

endmodule
