`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: DataExt 
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Data Extension module
//////////////////////////////////////////////////////////////////////////////////
//����˵��
    //DataExt������������ֶ���load�����Σ�ͬʱ����load�Ĳ�ͬģʽ��Data Mem��load�������з��Ż����޷�����չ������߼���·
//����
    //IN                    �Ǵ�Data Memory��load��32bit��
    //LoadedBytesSelect     �ȼ���AluOutM[1:0]���Ƕ�Data Memory��ַ�ĵ���λ��
                            //��ΪDataMemory�ǰ��֣�32bit�����з��ʵģ�������Ҫ���ֽڵ�ַת��Ϊ�ֵ�ַ����DataMem
                            //DataMemһ�η���һ���֣�����λ��ַ������32bit������ѡ��������Ҫ���ֽ�
    //RegWriteW             ��ʾ��ͬ�� �Ĵ���д��ģʽ ������ģʽ������Parameters.v��
//���
    //OUT��ʾҪд��Ĵ���������ֵ
//ʵ��Ҫ��  
    //��ȫģ��  

`include "Parameters.v"   
module DataExt(
    input wire [31:0] IN,
    input wire [1:0] LoadedBytesSelect,
    input wire [2:0] RegWriteW,
    output reg [31:0] OUT
    );    
    wire [31: 0] LoadByte = (IN >> (LoadedBytesSelect * 32'h8)) & 32'hff;
    wire [31: 0] LoadHalfWord = (IN >> (LoadedBytesSelect * 32'h8)) & 32'hffff;
    always@(*) 
    begin
        case (RegWriteW)
            `LB: OUT <= {{24{LoadByte[7]}}, LoadByte[7: 0]};
            `LH: OUT <= {{16{LoadHalfWord[15]}}, LoadHalfWord[15: 0]};
            `LW: OUT <= IN;
            `LBU: OUT <= {24'h0, LoadByte[7: 0]};
            `LHU: OUT <= {16'h0, LoadHalfWord[15: 0]};
        endcase
    end             
        // �벹ȫ�˴�����

endmodule

