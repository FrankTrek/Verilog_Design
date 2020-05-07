`default_nettype none
module SRAM_Manger(
    inout   wire[31:0] SRAM_io,      //SRAM的数据输入和输出
    output  reg [19:0] SRAM_addr,    //SRAM输入的地址
    output  reg        Read_Signal_n,  //读信号
    output  reg        Write_Signal_n, //写信号

    input   wire       Reset_n,      //复位
	input   wire[19:0] read_Address, //vga输入的地址
    input   wire       Clock,          //时钟信号
	output  reg [15:0] read_output,  //vga数据
	input   wire[19:0] write_Address,//画面处理器输入的地址
	input   wire[15:0] write_input   //画面处理器输入的数据
);
/*
    分为四个状态，写状态，写完成状态,读状态，读接受状态
*/  reg write_flag;
    reg[31:0] temp_io;  //暂态输入的数据
    reg[1:0] State, Next_State; //当前状态
    localparam  Write        =   2'b01;
                Write_End    =   2'b11;
                Read_Enable  =   2'b00;
                Read         =   2'b10;


    always@(posedge Clock)
    begin
        if(Reset_n == 0)
            begin
                write_flag <= 0;
                State <= Read_Enable;
                Next_State <= Read_Enable;
                temp_io <= 32'b0;
            end
        case(State)
        Read_Enable: Next_State <= Read;
        Read       : Next_State <= Write;
        Write      : Next_State <= Write_End;
        Write_End  : Next_State <= Read_Enable;
        default    : Next_State <= Read_Enable;
        endcase
    end

    always@(posedge Clock)
    begin
        case(State)
        Read_Enable: begin
                        write_flag <= 0; //将inout调节为高阻态
                        Read_Signal_n <= 0; //激活读
                        Write_Signal_n<= 1; //关闭写
                        SRAM_addr <= read_Address; //输入地址
                     end
        Read       : begin
                        read_output <= SRAM_io[15:0]; //读入数据
                     end
        Write      : begin
                        Read_Signal_n <= 1;
                        Write_Signal_n <= 0;
                        SRAM_addr <= write_Address;
                        temp_io[15:0] <=write_input; //写入数据
                        write_flag <=1 ; //开始写数据
                     end
        endcase
    end
    assign SRAM_io = write_flag ? temp_io : 32'bZ; //将写数据转接给SRAM_io

endmodule
