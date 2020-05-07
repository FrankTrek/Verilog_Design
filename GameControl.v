module GameControl(
    input wire[6:0] keyboard_input, //键盘输入信号
    input wire      rst_n,          //复位信号
    input wire      clock,          //时钟
    //输出暂时没想好
);
    //键盘输入常量
    localparam  data_posedge = 2'b01; //输入信号上升沿
    localparam  data_hold    = 2'b11; //输入信号保持
    localparam  data_negedge = 2'b10; //输入信号结束
    localparam  forward      = 5'b10000; //前进
    localparam  backward     = 5'b01000; //后退
    localparam  angle_up     = 5'b00100; //向上调节角度
    localparam  angle_down   = 5'b00010; //向下调节角度
    localparam  hold_cannon  = 5'b00001; //蓄力
    //状态机常量
    localparam  game_start   = 4'b0000; //游戏开始
    localparam  player1_turn = 4'b0101; //玩家一回合
    localparam  player1_move = 4'b0001; //玩家一运动
    localparam  player1_fire = 4'b0010; //玩家一炮弹发炮
    localparam  player1_cannon = 4'b0011; //炮弹判定
    localparam  player1_hit_check = 4'b0100; //玩家一攻击之后对受伤的判定
    localparam  player2_turn = 4'b0110; ////玩家二回合
    localparam  player2_move = 4'b0111; //玩家二运动
    localparam  player2_fire = 4'b1000; //玩家二发炮
    localparam  player2_cannon = 4'b1001; //炮弹判定
    localparam  player2_hit_check = 4'b1010; //受伤判定
    localparam  game_end     = 4'b1011;  //游戏结束


endmodule