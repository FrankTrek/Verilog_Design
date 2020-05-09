module player(

    input wire      hit, //被命中
    input wire[6:0] keyboard_input, //键盘输入信号
    input wire      rst_n,          //复位信号
    input wire      clock,          //时钟
    input wire[3:0] state,          //目前状态
    output wire[10:0] object_x,         //输出x坐标
    output wire[9:0] object_y,        //输出y坐标
    output wire     direction,      //面朝方向
    output wire[7:0] angle,          //角度
    output wire[7:0] power,           //力量
    output wire[7:0] health        //血量
);

    //状态机
    localparam STOP = 2'b00; //停止状态
    localparam FORWARD = 2'b01; //前进状态
    localparam UP = 2'b10; //爬墙状态
    localparam FALL = 2'b11; //坠落

    //键盘输入常量
    localparam  data_posedge = 2'b01; //输入信号上升沿
    localparam  data_hold    = 2'b11; //输入信号保持
    localparam  data_negedge = 2'b10; //输入信号结束
    localparam  forward      = 5'b10000; //前进
    localparam  backward     = 5'b01000; //后退
    localparam  angle_up     = 5'b00100; //向上调节角度
    localparam  angle_down   = 5'b00010; //向下调节角度
    localparam  hold_cannon  = 5'b00001; //蓄力
    localparam  player_1_init_x = 11'b0; //玩家1初始位置
    localparam  player_2_init_x = 11'b0; //玩家2初始位置
    localparam  init_y = 10'b0; //初始x的位置
    localparam  board_x = 12'h800; //游戏尺寸x
    localparam  board_y = 12'h600; // y
    localparam  health_loss = 8'h20; //每次收到攻击的血量
    localparam  drop_v = 8'h30; //坠落速度
    localparam  climb_v = 8'h20; //爬墙速度
    localparam  walk_v = 8'h20; //前进速度
    localparam  angle_v = 8'h10; //角度调节速度
    localparam  power_v = 8'h10; //蓄力速度
    //阵营全局常量, 初始化之后通过top实体直接指定
    parameter Position = 1'b0; // 0或1
    //状态
    reg [10:0] pos_x;
    reg [9:0] pos_y;
    reg [8:0] v_x ; //x方向速度 第一位为左右
    reg [8:0] v_y ; //y方向速度 第一位的上下
    reg [7:0] my_health; //血量
    reg my_direction; //方向
    reg [3:0] my_state; //状态
    reg [7:0] my_angle; //角度
    reg [7:0] my_power; //力量
    reg [1:0] my_turn; //状态
    assign object_x = pos_x;
    assign object_y = pos_y;
    assign direction = my_direction;
    assign health = my_health; 
	 assign angle = my_angle;
	 assign power = my_power;
    //内部位移用时钟信号
    reg my_clock;

    always @(posedge clock) //管理速度，状态，角度，力量(快时钟)
    begin
        if(rst_n == 0) //重置
        begin
            v_x <=8'h0;
            v_y <=8'h0;
            my_power <= 8'h0;
            my_angle <= 8'h0;
            my_state <= 4'b0100; //默认有支撑
            my_turn <= STOP;
        end
        else //正常
        begin
            if(state != 4'bz) //接收到有效信息
                my_state <= state; //更新状态

            case(my_turn) //根据状态
            STOP : begin
                    if(my_state[2] == 1) //下面有支撑
                    begin
                        if(keyboard_input[6:5] == data_posedge) //开始输入数据
                        begin
                            if(keyboard_input[4:0] == forward) //前进
                            begin
                                
                                if((my_state[3] == 0) & (my_state[0] == 1)) //若上方未受阻则开始爬墙
                                begin
                                    v_x <= {my_direction, 8'b0};
                                    v_y <= {1'b1,climb_v} ; //爬墙速度
                                    my_turn <= UP;
                                 end
                                 else if(my_state[0] == 0) //右方未受阻
                                 begin
                                     v_x <= {1'b0,walk_v};
                                     v_y[8] <= 0;
												 v_y[7:0] <= 8'b0;
                                     my_turn <= FORWARD;
                                 end
                              
                            end
                            else if(keyboard_input[4:0] == backward) //后退
                            begin
                                begin
                                    if((my_state[3] == 0) & (my_state[1] == 1)) //若上方未受阻则开始爬墙
                                    begin
                                        v_x <= {my_direction, 8'b0};
                                        v_y <= {1'b0,climb_v} ; //爬墙速度
                                        my_turn <= UP;
                                    end
                                    else if(my_state[1] == 0) //左方未受阻
                                    begin
                                        v_x <= {1'b0,walk_v};
                                        v_y <= {1'b0,8'b0};
                                        my_turn <= FORWARD;
                                    end
                                end
                            end
                            //速度也许需要调整
                            else if(keyboard_input[4:0] == angle_up) //上升角度
                            begin
                                if(my_angle + angle_v >= 8'h90) //达到上届
                                    my_angle <= 8'h90; 
                                else
                                    my_angle <= my_angle + angle_v; //否则上升
                            end
                            else if(keyboard_input[4:0] == angle_down) //下降角度
                            begin
                                if(my_angle < angle_v)
                                    my_angle <= 8'h0;
                                else
                                    my_angle = my_angle - angle_v;
                            end
                            else if(keyboard_input[4:0] == hold_cannon) //发炮
                            begin
                                if(my_power + power_v >= 8'h100)
                                    my_power <= 8'h100;
                                else
                                    my_power <= my_power + power_v;
                            end
                        end
                        else if(keyboard_input[6:5] == data_hold) //保持状态
                        begin
                            //和上文完全一样,只处理角度调整
                            if(keyboard_input[4:0] == angle_up) //上升角度
                            begin
                                if(my_angle + angle_v >= 8'h90) //达到上届
                                    my_angle <= 8'h90; 
                                else
                                    my_angle <= my_angle + angle_v; //否则上升
                            end
                            else if(keyboard_input[4:0] == angle_down) //下降角度
                            begin
                                if(my_angle < angle_v)
                                    my_angle <= 8'h0;
                                else
                                    my_angle = my_angle - angle_v;
                            end
                            else if(keyboard_input[4:0] == hold_cannon) //发炮
                            begin
                                if(my_power + power_v >= 8'h100)
                                    my_power <= 8'h100;
                                else
                                    my_power <= my_power + power_v;
                            end
                        end
                        //无下降状态
                    end
                    else //无支撑则坠落
                    begin
                        my_turn <= FALL; 
                        v_y <= {1'b1, drop_v}; //赋予速度
                    end
                end
            FORWARD : begin//前进状态
                        if(keyboard_input[6:5] == data_negedge) //数据输入结束
                        begin
                            v_x <= {my_direction, 8'b0}; //失去速度
                            v_y <= {1'b0,8'b0}; //失去速度
                            my_turn <= STOP; //停止
                        end
                        else if(keyboard_input[6:5] == data_hold) //正在输出数据
                        begin
                            if(my_direction == 0) //向左
                            begin
                                if((my_state[1] == 1)&(my_state[3] == 0)) //上方无阻挡
                                begin
                                    v_x <= {my_direction, 8'b0};
                                    v_y <= {1'b0,climb_v} ; //爬墙速度
                                    my_turn <= UP;
                                end
                                
                            end
                            else //向右
                            begin
                                if((my_state[0] == 1)&(my_state[3] == 0)) //上方无阻挡
                                begin
                                    v_x <= {my_direction, 8'b0};
                                    v_y <= {1'b0,climb_v} ; //爬墙速度
                                    my_turn <= UP;
                                end
                            end
                        end
                end
            UP :       begin //爬升
                        if(my_state[3] == 1) //上方收到阻挡
                        begin
                            v_x <= {my_direction,8'b0};
                            v_y <= {1'b0,8'b0};
                            my_turn <= STOP;
                        end
                end
            FALL :     begin //坠落
                        if(my_state[2] == 1) //下方有支撑
                        begin
                            v_y <= {1'b0,8'b0}; //停止下坠
                            my_turn <= STOP; //停止
                        end
                
                end
				default : ;
				endcase
        end
        
    end


    always @(posedge my_clock) //管理位置与血量（慢时钟）
    begin
        if(rst_n == 0) //重制
        begin
            if(Position == 0)
                pos_x <= player_1_init_x;
            else
                pos_x <= player_2_init_x;
            pos_y <= init_y; //初始化位置
            my_health <= 8'h100; //初始化血量
            my_direction <= Position; 
        end
        else
        begin
            if(v_x[7:0] != 8'b0)
				begin
					if(v_x[8] == 0) //左
					begin
						my_direction <= 0;
						if(pos_x < v_x[7:0]) //死亡
                    my_health <= 8'h0;
						else
                    pos_x = pos_x - v_x[7:0]; 
					end
					else //右
					begin
						my_direction <= 1;
						if((pos_x + v_x[7:0]) > board_x) //死亡
                    my_health <= 8'h0;
						else
                    pos_x = pos_x  + v_x[7:0]; 
					end
				end
				if(v_y[7:0] != 8'b0)
				begin
					if(v_y[8] == 0) //上
					begin
						if(pos_y < v_y[7:0]) //死亡
							my_health <= 8'h0;
						else
							pos_y = pos_y - v_y[7:0]; 
					end
					else //下
					begin
						if((pos_y + v_y[7:0]) > board_y) //死亡
							my_health <= 8'h0;
						else
							pos_y = pos_y  + v_y[7:0]; 
					end
				end
				if(hit == 1) //收到攻击
               if(my_health < health_loss)
                   my_health <= 0; //死亡
               else
                   my_health <= my_health - health_loss;
				
        end
        
    end



endmodule
