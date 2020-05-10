module cannon(
    input wire      cannon_trun, //是否为此时炮弹的轮次
    input wire[3:0] state, //状态
    input wire      clock_50m, //读时钟
    input wire      clock_check_clide, //检测碰撞
    input wire      clock, //运动时钟（慢
    input wire      rst_n,
    input wire[17:0] start_pos_x, //初始的x位置
    input wire[17:0] start_pos_y, //初始的y位置
    input wire       direction,// 面朝方向
    input wire[7:0]  angle, //角度
    input wire[7:0]  power, //力度

    output wire[17:0] pos_x, //x坐标
    output wire[17:0] pos_y, //y坐标
    output reg[1:0]  clide_state //碰撞报警
);
    localparam write_sin = 2'b00; //读入sin地址
    localparam read_sin = 2'b01;
    localparam write_cos = 2'b10; //读入cos地址
    localparam read_cos = 2'b11;
    reg [1:0]rw_state; //读写状态
    
    wire[7:0] sine_output; //从端口中输出的
    reg[7:0] sine;
    reg[7:0] cosine;
    reg flag; 
    wire [7:0] sine_input; //输入rom的地址
    wire [7:0] cos_angle; //余弦角度
    assign cos_angle = angle + 8'h90; 
    assign pos_x = mypos_x;
    assign pos_y = mypos_y;
    assign sine_output = flag ? angle : cos_angle; 

    sin sin_rom((
	    .address(sine_input),
	    .clock(clock_50m),
	    .q(sine_output),
    );
    

    always @(clock_50m)
    begin
        if(rst_n == 0)
        begin
            rw_state <= write_sin;
            flag < 1'b1;
        end
        else
        begin
            case(state)
            write_sin : begin
                        flag<= 1'b1;
                        state <= read_sin;
                    end
            read_sin : begin
                        sine <= sine_output;
                        state <= write_cos;
                    end
            write_cos : begin
                        flag <= 1'b0;
                        state <= read_cos;
                    end
            read_cos : begin
                        cosine <= sine_output;
                        state <= write_sin;
                    end
            endcase
        end 
    end //解决了写入的问题
    localparam HOLD = 1'b0; //平时的等待状态
    localparam FLY = 1'b1;  //飞行
    localparam  board_x = 18'h80000; //游戏尺寸x
    localparam  board_y = 18'h60000; // y
    localparam g_constant = 8'h100; //重力加速度
    reg[17:0] mypos_x;
    reg[17:0] mypos_y; //此时的位置
    reg[17:0] v_x;
    reg[17:0] v_y;
    reg[3:0] my_state; //碰撞系统
    reg [1:0]my_direction; //方向 0上1下,0左1右
    reg  game_state; //我的状态
    always @(clock_check_clide)
        if(state != 4'bz)
            my_state <= state;  //存下此时碰撞系统的状态

    always @(clock) //慢时钟
    begin
        if(rst_n)
        begin
            mypos_x <= 18'b0;
            mypos_y <= 18'b0;
            v_x <= 18'b0;
            v_y <= 18'b0;
            my_direction <= 2'b00;
            game_state <= HOLD;
            clide_state <= 2'b00;
        end
        else
        begin
            case(game_state)
            HOLD : begin
                    if(cannon_trun == 1)
                    begin
                        my_direction[0] <= direction ;//存下位置
                        my_direction[1] <= 1'b0; //向上飞
                        mypos_x <= start_pos_x;
                        mypos_y <= start_pos_y;
                        v_x = power * cosine;
                        v_y = power * sine; //赋予速度
                        game_state <= FLY; //进入飞
                    end
                    else
                        game_state <= HOLD;
                end
            FLY : begin
                        if((my_state[3] == 1'b1) | (my_state[2] == 1'b1) | (my_state[1] == 1'b1) | (my_state[0] == 1'b0)) //发生了碰撞
                        begin
                                clide_state <= 2'b01; //爆炸
                                game_state <= HOLD;
                        end
                        else 
                        begin
                            if(my_direction[] == 0) //向左
                            begin
                                if(mypos_x < v_x)
                                begin
                                    mypos_x <= 0;
                                    clide_state <= 2'b10; //没有爆炸
                                    game_state <= HOLD; //终止
                                end
                                else 
                                begin
                                    mypos_x <= mypos_x - v_x;
                                    game_state <= FLY;
                                end
                            end
                            else //向右
                            begin
                                if(mypos_x + v_x > board_x)
                                begin
                                    mypos_x <= board_x;
                                    clide_state <= 2'b10; //没有爆炸
                                    game_state <= HOLD; //终止
                                end
                                else 
                                begin
                                    mypos_x <= mypos_x + v_x;
                                    game_state <= FLY;
                                end
                            end
                            if(my_direction[1] == 0) //向上
                            begin
                                if(mypos_y < v_y)
                                begin
                                    mypos_y <= 0;
                                    clide_state <= 2'b10; //没有爆炸
                                    game_state <= HOLD; //终止
                                end
                                else
                                begin
                                    mypos_y <= mypos_y - v_y;
                                    if(v_y < g_constant)
                                    begin
                                        v_y <= 18'b0;
                                        my_direction[1] <= 1'b1; //改为下坠
                                        game_state <= FLY;
                                    end
                                    else
                                        v_y <= v_y - g_constant; //重力加速度
                                end
                            end
                            else //向下
                            begin
                                if(mypos_y + v_y > board_y)
                                begin
                                    mypos_y <= board_y;
                                    clide_state <= 2'b10; //没有爆炸
                                    game_state <= HOLD; //终止
                                end
                                else //没有到边线
                                begin
                                    mypos_y <= mypos_y + v_y;
                                    v_y <= v_y + g_constant;
                                end
                            end
                               

                        end
                
                end
            endcase
        end
    end


endmodule
