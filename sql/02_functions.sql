-- ==========================================
-- 游戏记账系统函数和存储过程
-- 创建时间: 2024-01-XX
-- 数据库类型: PostgreSQL 12+
-- ==========================================

-- ==========================================
-- 工具函数
-- ==========================================

-- 生成UUID（兼容函数）
CREATE OR REPLACE FUNCTION generate_id() 
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN REPLACE(gen_random_uuid()::TEXT, '-', '');
END;
$$;

-- 生成房间邀请码
CREATE OR REPLACE FUNCTION generate_room_code() 
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    code VARCHAR(20);
    counter INT DEFAULT 0;
BEGIN
    LOOP
        code := CHR(65 + FLOOR(RANDOM() * 26)::INT) ||
                CHR(65 + FLOOR(RANDOM() * 26)::INT) ||
                CHR(65 + FLOOR(RANDOM() * 26)::INT) ||
                LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0');
        
        counter := counter + 1;
        
        EXIT WHEN NOT EXISTS (SELECT 1 FROM rooms WHERE room_code = code) OR counter > 10;
    END LOOP;
    
    RETURN code;
END;
$$;

-- 计算用户余额
CREATE OR REPLACE FUNCTION calculate_user_balance(
    user_id_param VARCHAR(50), 
    room_id_param VARCHAR(50)
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_received NUMERIC(10,2) DEFAULT 0;
    total_paid NUMERIC(10,2) DEFAULT 0;
    balance NUMERIC(10,2) DEFAULT 0;
BEGIN
    -- 计算收入
    SELECT COALESCE(SUM(amount), 0) INTO total_received
    FROM transactions 
    WHERE to_player_id = user_id_param 
      AND room_id = room_id_param 
      AND status = 'COMPLETED';
    
    -- 计算支出
    SELECT COALESCE(SUM(amount), 0) INTO total_paid
    FROM transactions 
    WHERE from_player_id = user_id_param 
      AND room_id = room_id_param 
      AND status = 'COMPLETED';
    
    balance := total_received - total_paid;
    RETURN balance;
END;
$$;

-- 计算胜率
CREATE OR REPLACE FUNCTION calculate_win_rate(
    wins_param INT, 
    total_games_param INT
)
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql
AS $$
BEGIN
    IF total_games_param = 0 THEN
        RETURN 0.00;
    END IF;
    RETURN ROUND((wins_param::NUMERIC / total_games_param::NUMERIC) * 100, 2);
END;
$$;

-- ==========================================
-- 用户管理存储过程
-- ==========================================

-- 创建用户
CREATE OR REPLACE FUNCTION create_user(
    user_name VARCHAR(100),
    user_avatar VARCHAR(255),
    user_phone VARCHAR(20),
    user_email VARCHAR(100),
    OUT user_id VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    user_id := generate_id();
    
    INSERT INTO users (id, name, avatar, phone, email, balance, is_host, status)
    VALUES (user_id, user_name, user_avatar, user_phone, user_email, 0.00, FALSE, 'ACTIVE');
    
    -- 初始化游戏统计
    INSERT INTO game_stats (
        id, user_id, total_games, wins, losses, draws, 
        win_rate, total_points, total_earnings, total_losses, friend_ranking
    )
    VALUES (
        generate_id(), user_id, 0, 0, 0, 0, 
        0.00, 0.00, 0.00, 0.00, 0
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- 更新用户信息
CREATE OR REPLACE FUNCTION update_user(
    user_id_param VARCHAR(50),
    user_name VARCHAR(100) DEFAULT NULL,
    user_avatar VARCHAR(255) DEFAULT NULL,
    user_phone VARCHAR(20) DEFAULT NULL,
    user_email VARCHAR(100) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    rows_affected INT;
BEGIN
    UPDATE users 
    SET name = COALESCE(user_name, name),
        avatar = COALESCE(user_avatar, avatar),
        phone = COALESCE(user_phone, phone),
        email = COALESCE(user_email, email),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_id_param;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    IF rows_affected = 0 THEN
        RAISE EXCEPTION 'User not found';
    END IF;
END;
$$;

-- ==========================================
-- 房间管理存储过程
-- ==========================================

-- 创建房间
CREATE OR REPLACE FUNCTION create_room(
    room_name VARCHAR(200),
    host_id_param VARCHAR(50),
    max_players_param INT DEFAULT 20,
    settings_param JSONB DEFAULT NULL,
    OUT room_id VARCHAR(50),
    OUT room_code_out VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    room_id := generate_id();
    room_code_out := generate_room_code();
    
    INSERT INTO rooms (id, name, host_id, room_code, max_players, status, settings)
    VALUES (room_id, room_name, host_id_param, room_code_out, 
            COALESCE(max_players_param, 20), 'ACTIVE', settings_param);
    
    -- 添加房主到房间成员
    INSERT INTO room_members (id, room_id, user_id, role)
    VALUES (generate_id(), room_id, host_id_param, 'HOST');
    
    -- 更新用户为房主状态
    UPDATE users SET is_host = TRUE WHERE id = host_id_param;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- 加入房间
CREATE OR REPLACE FUNCTION join_room(
    room_code_param VARCHAR(20),
    user_id_param VARCHAR(50),
    nickname_param VARCHAR(100) DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    room_id_var VARCHAR(50);
    current_players INT;
    max_players_var INT;
    room_status_var room_status;
BEGIN
    -- 获取房间信息
    SELECT id, max_players, status 
    INTO room_id_var, max_players_var, room_status_var
    FROM rooms 
    WHERE room_code = room_code_param;
    
    -- 检查房间是否存在
    IF room_id_var IS NULL THEN
        RAISE EXCEPTION 'Room not found';
    END IF;
    
    -- 检查房间状态
    IF room_status_var != 'ACTIVE' THEN
        RAISE EXCEPTION 'Room is not active';
    END IF;
    
    -- 检查是否已经是成员
    IF EXISTS (
        SELECT 1 FROM room_members 
        WHERE room_id = room_id_var AND user_id = user_id_param AND left_at IS NULL
    ) THEN
        RAISE EXCEPTION 'User already in room';
    END IF;
    
    -- 检查房间人数
    SELECT COUNT(*) INTO current_players
    FROM room_members 
    WHERE room_id = room_id_var AND left_at IS NULL;
    
    IF current_players >= max_players_var THEN
        RAISE EXCEPTION 'Room is full';
    END IF;
    
    -- 加入房间
    INSERT INTO room_members (id, room_id, user_id, nickname, role)
    VALUES (generate_id(), room_id_var, user_id_param, nickname_param, 'MEMBER');
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- 离开房间
CREATE OR REPLACE FUNCTION leave_room(
    room_id_param VARCHAR(50),
    user_id_param VARCHAR(50)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    is_host_var BOOLEAN DEFAULT FALSE;
    rows_affected INT;
BEGIN
    -- 检查是否为房主
    SELECT role = 'HOST' INTO is_host_var
    FROM room_members 
    WHERE room_id = room_id_param AND user_id = user_id_param AND left_at IS NULL;
    
    -- 更新离开时间
    UPDATE room_members 
    SET left_at = CURRENT_TIMESTAMP 
    WHERE room_id = room_id_param AND user_id = user_id_param AND left_at IS NULL;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    IF rows_affected = 0 THEN
        RAISE EXCEPTION 'User not in room or already left';
    END IF;
    
    -- 如果是房主离开，更新用户表
    IF is_host_var THEN
        UPDATE users SET is_host = FALSE WHERE id = user_id_param;
        
        -- 如果房间还有其他成员，可以考虑转让房主权限或关闭房间
        -- 这里选择关闭房间
        UPDATE rooms SET status = 'CLOSED', closed_at = CURRENT_TIMESTAMP 
        WHERE id = room_id_param;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- ==========================================
-- 交易管理存储过程
-- ==========================================

-- 创建交易
CREATE OR REPLACE FUNCTION create_transaction(
    room_id_param VARCHAR(50),
    from_player_id_param VARCHAR(50),
    to_player_id_param VARCHAR(50),
    amount_param NUMERIC(10,2),
    description_param TEXT DEFAULT NULL,
    type_param transaction_type DEFAULT 'TRANSFER',
    metadata_param JSONB DEFAULT NULL,
    OUT transaction_id VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 验证金额
    IF amount_param <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;
    
    -- 验证玩家是否在房间中
    IF NOT EXISTS (
        SELECT 1 FROM room_members 
        WHERE room_id = room_id_param AND user_id = from_player_id_param AND left_at IS NULL
    ) THEN
        RAISE EXCEPTION 'From player not in room';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM room_members 
        WHERE room_id = room_id_param AND user_id = to_player_id_param AND left_at IS NULL
    ) THEN
        RAISE EXCEPTION 'To player not in room';
    END IF;
    
    transaction_id := generate_id();
    
    INSERT INTO transactions (
        id, room_id, from_player_id, to_player_id, amount, 
        description, type, status, metadata
    )
    VALUES (
        transaction_id, room_id_param, from_player_id_param, to_player_id_param, 
        amount_param, description_param, type_param, 'COMPLETED', metadata_param
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- 结算房间
CREATE OR REPLACE FUNCTION settle_room(room_id_param VARCHAR(50))
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    member_record RECORD;
    user_balance NUMERIC(10,2);
    rank_counter INT := 1;
BEGIN
    -- 检查房间状态
    IF NOT EXISTS (SELECT 1 FROM rooms WHERE id = room_id_param AND status = 'ACTIVE') THEN
        RAISE EXCEPTION 'Room not found or not active';
    END IF;
    
    -- 清除旧的结算结果
    DELETE FROM settlement_results WHERE room_id = room_id_param;
    
    -- 为每个成员计算结算结果
    FOR member_record IN 
        SELECT user_id FROM room_members 
        WHERE room_id = room_id_param AND left_at IS NULL
        ORDER BY user_id
    LOOP
        -- 计算用户在房间内的余额
        user_balance := calculate_user_balance(member_record.user_id, room_id_param);
        
        -- 插入结算结果
        INSERT INTO settlement_results (
            id, room_id, user_id, final_balance, 
            total_transferred, total_received, 
            settlement_rank, is_winner
        )
        SELECT 
            generate_id(),
            room_id_param,
            member_record.user_id,
            user_balance,
            COALESCE(SUM(CASE WHEN from_player_id = member_record.user_id THEN amount ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN to_player_id = member_record.user_id THEN amount ELSE 0 END), 0),
            rank_counter,
            user_balance > 0
        FROM transactions 
        WHERE room_id = room_id_param 
          AND (from_player_id = member_record.user_id OR to_player_id = member_record.user_id)
          AND status = 'COMPLETED';
        
        rank_counter := rank_counter + 1;
    END LOOP;
    
    -- 更新排名（按最终余额排序）
    WITH ranked_results AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY final_balance DESC) as new_rank
        FROM settlement_results 
        WHERE room_id = room_id_param
    )
    UPDATE settlement_results 
    SET settlement_rank = ranked_results.new_rank
    FROM ranked_results 
    WHERE settlement_results.id = ranked_results.id;
    
    -- 更新房间状态为已结算
    UPDATE rooms 
    SET status = 'SETTLED', updated_at = CURRENT_TIMESTAMP 
    WHERE id = room_id_param;
    
    -- 更新用户统计数据
    PERFORM update_user_stats_after_settlement(room_id_param);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;

-- 更新用户统计数据（结算后）
CREATE OR REPLACE FUNCTION update_user_stats_after_settlement(room_id_param VARCHAR(50))
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    result_record RECORD;
BEGIN
    FOR result_record IN 
        SELECT user_id, final_balance, is_winner 
        FROM settlement_results 
        WHERE room_id = room_id_param
    LOOP
        UPDATE game_stats 
        SET total_games = total_games + 1,
            wins = wins + CASE WHEN result_record.is_winner THEN 1 ELSE 0 END,
            losses = losses + CASE WHEN NOT result_record.is_winner AND result_record.final_balance < 0 THEN 1 ELSE 0 END,
            draws = draws + CASE WHEN NOT result_record.is_winner AND result_record.final_balance = 0 THEN 1 ELSE 0 END,
            total_points = total_points + result_record.final_balance,
            total_earnings = total_earnings + CASE WHEN result_record.final_balance > 0 THEN result_record.final_balance ELSE 0 END,
            total_losses = total_losses + CASE WHEN result_record.final_balance < 0 THEN ABS(result_record.final_balance) ELSE 0 END,
            last_game_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = result_record.user_id;
        
        -- 重新计算胜率
        UPDATE game_stats 
        SET win_rate = calculate_win_rate(wins, total_games)
        WHERE user_id = result_record.user_id;
    END LOOP;
END;
$$;

-- ==========================================
-- 统计和查询函数
-- ==========================================

-- 获取房间统计信息
CREATE OR REPLACE FUNCTION get_room_stats(room_id_param VARCHAR(50))
RETURNS TABLE (
    total_members INT,
    active_members INT,
    total_transactions INT,
    total_amount NUMERIC(10,2),
    room_status room_status
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM room_members WHERE room_id = room_id_param)::INT,
        (SELECT COUNT(*) FROM room_members WHERE room_id = room_id_param AND left_at IS NULL)::INT,
        (SELECT COUNT(*) FROM transactions WHERE room_id = room_id_param)::INT,
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE room_id = room_id_param AND status = 'COMPLETED'),
        (SELECT status FROM rooms WHERE id = room_id_param);
END;
$$;

-- 获取用户在房间中的余额
CREATE OR REPLACE FUNCTION get_user_room_balance(
    user_id_param VARCHAR(50),
    room_id_param VARCHAR(50)
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN calculate_user_balance(user_id_param, room_id_param);
END;
$$;

-- ==========================================
-- 完成提示
-- ==========================================
SELECT 'Functions and procedures created successfully!' AS message; 