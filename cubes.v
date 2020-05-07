module Cubes(
    input wire game_state, //输入状态 0为正常碰撞检测，1为炮弹爆炸时消去方块
    input wire rst_n, //清零
    input wire clock_1M,  //时钟 1M的频率
    //当前物体信息
    input wire       id,        //0为炮弹，1为人
    input wire[10:0] object_x,  //目前运动物体的x坐标
    input wire[9:0]  object_y,  // y坐标
    output reg[3:0]  object_states, // 输出的状态
    output wire[49:0] cube_states_output 
);
    localparam collide_check = 1'b0; //碰撞检测
    localparam explode_check = 1'b1; //爆炸
    localparam half_cube_size = 8'h40; //半个方块
    localparam init_cube_state = {50{1'b1}}; //初始化
    localparam cube_size = 8'h80; //方块尺寸
    localparam top_cube_height = 8'h200; //起始方块位置 纵200-600，横0-800
    localparam num_cubes = 8'h50; //一共50个方块
    localparam num_vertical = 4'h10; //横向有10个方块
    localparam num_horizontal = 4'h5; //纵向有5个方块
    localparam object_size = 8'h50; //物体尺寸 50x50
    localparam explode_rad = 10000; //爆炸半径的平方
    /*接下来为检测碰撞，
    水平方向碰撞为物体与方块中心小于等于65，
    位于方块之下被顶到判定为小于等于65，
    位于方块之上被支撑为距离小于等于65且水平方向距离小于70，
    */
    localparam collide_dist = 8'h65;
    localparam suppot_wide =  8'h70;
    //  状态
    reg[49:0] cube_states;   //方块状态
    reg[7:0]  current_cube_x; //目前方块的是横向第几个
    reg[7:0]  current_cube_y; //目前方块是纵向第几个
    reg[10:0] cube_pos_x; //目前处理的方块的中心——x
    reg[9:0]  cube_pos_y; //目前处理的方块的——y
    reg[7:0]  current_cube_id;
    reg[3:0]  flag; //标，用于进行判断
    integer dist_x; //距离(用于算数)
    integer dist_y; //距离
    always @(posedge clock_1M)
    begin
        if(rst_n == 0) //清零
        begin
            cube_states <= init_cube_state ; 
            cube_pos_x <= half_cube_size;
            cube_pos_y <= top_cube_height + half_cube_size; 
            current_cube_id <= 8'b0; 
            object_states <= 4'b0; //支撑取消
            current_cube_x = 8'b0;
            current_cube_y = 8'b0;
            flag <=4'b0;
        end
        else //正常状态
        begin

            if(game_state == collide_check) //检查碰撞
            begin
                //组合逻辑阻塞
                //上方碰撞
                flag[3] = (cube_pos_y > object_y)&(cube_pos_y - object_y <= collide_dist);  //高度满足碰撞条件
                flag[2] = (cube_pos_x > object_x)&(cube_pos_x - object_x <= collide_dist);
                flag[1] = (cube_pos_x < object_x)&(object_x - cube_pos_x <= collide_dist); //水平位置
                if(flag[3] & (flag[2] | flag[1]))
                    object_states[3] <= 1;
                else
                    object_states[3] <= 0;
                //左方碰撞检测
                flag[3] = (cube_pos_x < object_x)&(object_x - cube_pos_x <= collide_dist); //与左边方块距离满足碰撞条件
                flag[2] = (cube_pos_y > object_y)&(cube_pos_y - object_y <= collide_dist); //垂直位置
                flag[1] = (cube_pos_y < object_y)&(object_y - cube_pos_y <= collide_dist);
                if(flag[3] & (flag[2] | flag[1]))
                    object_states[1] <= 1;
                else
                    object_states[1] <= 0;
                //右方碰撞检测
                flag[3] = (cube_pos_x > object_x)&(cube_pos_x - object_x <= collide_dist); //与右边方块距离满足碰撞条件
                flag[2] = (cube_pos_y > object_y)&(cube_pos_y - object_y <= collide_dist); //垂直位置
                flag[1] = (cube_pos_y < object_y)&(object_y - cube_pos_y <= collide_dist);
                if(flag[3] & (flag[2] | flag[1]))
                    object_states[0] <= 1;
                else
                    object_states[0] <= 0;
                //上方支撑检测
                flag[3] = (cube_pos_y < object_y)&(object_y - cube_pos_y <= collide_dist); //在上方
                flag[2] = (cube_pos_x > object_x)&(cube_pos_x - object_x <= suppot_wide);
                flag[1] = (cube_pos_x < object_x)&(object_x - cube_pos_x <= suppot_wide); //水平位置
                if(flag[3] & (flag[2] | flag[1]))
                    object_states[2] <= 1;
                else
                    object_states[2] <= 0;
            end
            else if(game_state == explode_check) //爆炸检测
            begin
                dist_x = cube_pos_x - object_x;
                dist_y = cube_pos_y - object_y;
                if(dist_x*dist_x + dist_y*dist_y <= explode_rad) //小于爆炸半径
                    cube_states[current_cube_id] <= 0;
                else
                    cube_states[current_cube_id] <= 1;
            end

            
            //开始时序逻辑
            if(current_cube_id < 49)
                current_cube_id <= current_cube_id + 1;
            else
                current_cube_id <= 0;
            //x位置
            if(current_cube_x < num_horizontal) //没有到最右边
            begin
                current_cube_x <= current_cube_x + 1;
                cube_pos_x <= cube_pos_x + cube_size;
            end
            else
            begin
                current_cube_x <= 0;
                cube_pos_x <= half_cube_size;
                //y位置
                if(current_cube_y < num_vertical) //没到右边
                begin
                current_cube_y <= current_cube_y + 1;
                cube_pos_y <= cube_pos_y + cube_size;
                end
                else
                begin
                    current_cube_y = 0;
                    cube_pos_y <= top_cube_height + half_cube_size;
                end
            end
        end
    end




endmodule