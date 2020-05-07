module momentum(
    input wire clk_slow, //周期为方块钟表的1/50
    input wire rst_n,    //复位
    input wire[10:0] player1_x,  //玩家1的x坐标
    input wire[9:0]  player1_y,  // y坐标
    input wire[10:0] player2_x,  //玩家2的x坐标
    input wire[9:0]  player2_y,  // y坐标
    input wire[10:0] cannon_x,  //炮弹的x坐标
    input wire[9:0]  cannon_y,  // y坐标
    input wire[3:0] object_state, //目前物体状态
    output reg[10:0] object_x,  //目前运动物体的x坐标
    output reg[9:0]  object_y,  // y坐标
    output reg[3:0] player_1_state, //玩家1状态
    output reg[3:0] player_2_state, //玩家2状态
    output reg[3:0] cannon_state //玩家2状态
);
    localparam default_pos_x = 11'bz;
    localparam default_pos_y = 10'bz; //当炮弹不在场上的时候直接跳过
    localparam PLAYER1 = 2'b00; //此时查看玩家一的状态
    localparam PLAYER2 = 2'b01;
    localparam CANNON_S = 2'b10; //考虑到延迟，最开始接入的时候大炮收到的信息为玩家二的最后信息，所以这个状态强制输入0
    localparam CANNON_E = 2'b11;
    reg [1:0] state; //目前状态
    always @(posedge clk_slow)
    begin
        if(rst_n == 0)
        begin
            object_x <= 11'b0;
            object_y <= 10'b0;
            player_1_state <= 4'bz; //规定z时不理会
            player_2_state <= 4'bz;
            cannon_state <= 4'bz;
            state <= PLAYER1;  //状态机复位
        end 
        else //状态机
        begin
            case(state)
            PLAYER1 : begin //玩家一
                        player_1_state <=  object_state; //规定z时不理会
                        player_2_state <= 4'bz;
                        cannon_state <= 4'bz;
                        object_x <= player1_x;
                        object_y <= player1_y;
                        state <= PLAYER2;
                    end
            PLAYER2 : begin
                        player_1_state <=  4'bz; //规定z时不理会
                        player_2_state <= object_state;
                        cannon_state <= 4'bz;
                        object_x <= player2_x;
                        object_y <= player2_y;
                        state <= CANNON_S;
                    end
            CANNON_S : begin
                        player_1_state <=  4'bz; //规定z时不理会
                        player_2_state <= 4'bz;
                        cannon_state <= 4'b0;  //输入0
                        object_x <= cannon_x;
                        object_y <= cannon_y;    
                        state <= CANNON_E;
                    end
            CANNON_E : begin
                        player_1_state <=  4'bz; //规定z时不理会
                        player_2_state <= 4'bz;
                        cannon_state <= object_state;  //输入正常对应的状态
                        object_x <= cannon_x;
                        object_y <= cannon_y;    
                        state <= PLAYER1;
                    end
            default : ;//状态已经不重不漏了
        end
    end




endmodule