-- ==========================================
-- 游戏记账系统触发器
-- 创建时间: 2024-01-XX
-- 数据库类型: PostgreSQL 12+
-- ==========================================

-- ==========================================
-- 用户相关触发器
-- ==========================================

-- 用户创建后自动创建游戏统计记录
CREATE OR REPLACE FUNCTION tr_users_after_insert_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果没有对应的统计记录，则创建
    IF NOT EXISTS (SELECT 1 FROM game_stats WHERE user_id = NEW.id) THEN
        INSERT INTO game_stats (
            id, user_id, total_games, wins, losses, draws, 
            win_rate, total_points, total_earnings, total_losses, friend_ranking
        )
        VALUES (
            REPLACE(gen_random_uuid()::TEXT, '-', ''), NEW.id, 0, 0, 0, 0, 
            0.00, 0.00, 0.00, 0.00, 0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_users_after_insert ON users;
CREATE TRIGGER tr_users_after_insert
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION tr_users_after_insert_func();

-- 用户删除前清理相关数据
CREATE OR REPLACE FUNCTION tr_users_before_delete_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 记录删除日志
    INSERT INTO system_configs (config_key, config_value, description, config_type)
    VALUES (
        'user_deleted_' || OLD.id,
        jsonb_build_object('user_id', OLD.id, 'name', OLD.name, 'deleted_at', NOW()),
        '用户删除记录',
        'JSON'
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_users_before_delete ON users;
CREATE TRIGGER tr_users_before_delete
    BEFORE DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION tr_users_before_delete_func();

-- ==========================================
-- 房间相关触发器
-- ==========================================

-- 房间创建后初始化设置
CREATE OR REPLACE FUNCTION tr_rooms_after_insert_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果没有设置，则使用默认设置
    IF NEW.settings IS NULL THEN
        UPDATE rooms 
        SET settings = '{
            "allowNegativeBalance": false,
            "autoSettle": false,
            "maxTransactionAmount": 10000,
            "transactionTypes": ["TRANSFER", "EXPENSE"],
            "notifications": {"transaction": true, "settlement": true}
        }'::jsonb
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_rooms_after_insert ON rooms;
CREATE TRIGGER tr_rooms_after_insert
    AFTER INSERT ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION tr_rooms_after_insert_func();

-- 房间状态变更记录
CREATE OR REPLACE FUNCTION tr_rooms_after_update_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 记录状态变更
    IF OLD.status != NEW.status THEN
        INSERT INTO system_configs (config_key, config_value, description, config_type)
        VALUES (
            'room_status_change_' || NEW.id || '_' || EXTRACT(EPOCH FROM NOW())::TEXT,
            jsonb_build_object(
                'room_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'changed_at', NOW(),
                'host_id', NEW.host_id
            ),
            '房间状态变更记录',
            'JSON'
        );
    END IF;
    
    -- 房间关闭时的处理
    IF NEW.status = 'CLOSED' AND OLD.status != 'CLOSED' THEN
        -- 设置所有未离开的成员的离开时间
        UPDATE room_members 
        SET left_at = CURRENT_TIMESTAMP 
        WHERE room_id = NEW.id AND left_at IS NULL;
        
        -- 更新房主状态
        UPDATE users 
        SET is_host = FALSE 
        WHERE id = NEW.host_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_rooms_after_update ON rooms;
CREATE TRIGGER tr_rooms_after_update
    AFTER UPDATE ON rooms
    FOR EACH ROW
    EXECUTE FUNCTION tr_rooms_after_update_func();

-- ==========================================
-- 房间成员相关触发器
-- ==========================================

-- 房间成员加入后的处理
CREATE OR REPLACE FUNCTION tr_room_members_after_insert_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果是房主，更新用户表的房主状态
    IF NEW.role = 'HOST' THEN
        UPDATE users SET is_host = TRUE WHERE id = NEW.user_id;
    END IF;
    
    -- 记录加入日志
    INSERT INTO system_configs (config_key, config_value, description, config_type)
    VALUES (
        'member_joined_' || NEW.room_id || '_' || NEW.user_id,
        jsonb_build_object(
            'room_id', NEW.room_id,
            'user_id', NEW.user_id,
            'role', NEW.role,
            'joined_at', NEW.joined_at
        ),
        '成员加入房间记录',
        'JSON'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_room_members_after_insert ON room_members;
CREATE TRIGGER tr_room_members_after_insert
    AFTER INSERT ON room_members
    FOR EACH ROW
    EXECUTE FUNCTION tr_room_members_after_insert_func();

-- 房间成员离开后的处理
CREATE OR REPLACE FUNCTION tr_room_members_after_update_func()
RETURNS TRIGGER AS $$
BEGIN
    -- 成员离开时的处理
    IF OLD.left_at IS NULL AND NEW.left_at IS NOT NULL THEN
        -- 如果是房主离开，清除房主状态
        IF NEW.role = 'HOST' THEN
            UPDATE users SET is_host = FALSE WHERE id = NEW.user_id;
        END IF;
        
        -- 记录离开日志
        INSERT INTO system_configs (config_key, config_value, description, config_type)
        VALUES (
            'member_left_' || NEW.room_id || '_' || NEW.user_id,
            jsonb_build_object(
                'room_id', NEW.room_id,
                'user_id', NEW.user_id,
                'role', NEW.role,
                'left_at', NEW.left_at,
                'duration_minutes', EXTRACT(EPOCH FROM (NEW.left_at - NEW.joined_at))/60
            ),
            '成员离开房间记录',
            'JSON'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_room_members_after_update ON room_members;
CREATE TRIGGER tr_room_members_after_update
    AFTER UPDATE ON room_members
    FOR EACH ROW
    EXECUTE FUNCTION tr_room_members_after_update_func();

-- ==========================================
-- 交易相关触发器
-- ==========================================

-- 交易创建后的处理
CREATE OR REPLACE FUNCTION tr_transactions_after_insert_func()
RETURNS TRIGGER AS $$
DECLARE
    from_balance NUMERIC(10,2);
    to_balance NUMERIC(10,2);
BEGIN
    -- 只有完成状态的交易才更新余额
    IF NEW.status = 'COMPLETED' THEN
        -- 计算房间内用户余额
        SELECT COALESCE(SUM(CASE 
            WHEN to_player_id = NEW.from_player_id THEN amount 
            WHEN from_player_id = NEW.from_player_id THEN -amount 
            ELSE 0 END), 0) INTO from_balance
        FROM transactions 
        WHERE (from_player_id = NEW.from_player_id OR to_player_id = NEW.from_player_id)
          AND room_id = NEW.room_id 
          AND status = 'COMPLETED';
        
        SELECT COALESCE(SUM(CASE 
            WHEN to_player_id = NEW.to_player_id THEN amount 
            WHEN from_player_id = NEW.to_player_id THEN -amount 
            ELSE 0 END), 0) INTO to_balance
        FROM transactions 
        WHERE (from_player_id = NEW.to_player_id OR to_player_id = NEW.to_player_id)
          AND room_id = NEW.room_id 
          AND status = 'COMPLETED';
        
        -- 更新用户全局余额
        UPDATE users SET balance = balance - NEW.amount WHERE id = NEW.from_player_id;
        UPDATE users SET balance = balance + NEW.amount WHERE id = NEW.to_player_id;
    END IF;
    
    -- 记录交易日志
    INSERT INTO system_configs (config_key, config_value, description, config_type)
    VALUES (
        'transaction_created_' || NEW.id,
        jsonb_build_object(
            'transaction_id', NEW.id,
            'room_id', NEW.room_id,
            'from_player_id', NEW.from_player_id,
            'to_player_id', NEW.to_player_id,
            'amount', NEW.amount,
            'type', NEW.type,
            'status', NEW.status,
            'created_at', NEW.created_at
        ),
        '交易创建记录',
        'JSON'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_transactions_after_insert ON transactions;
CREATE TRIGGER tr_transactions_after_insert
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION tr_transactions_after_insert_func();

-- 交易状态更新后的处理
DROP TRIGGER IF EXISTS tr_transactions_after_update ON transactions;

CREATE OR REPLACE FUNCTION transactions_after_update()
RETURNS TRIGGER AS $$
BEGIN
    -- 交易状态变更处理
    IF OLD.status != NEW.status THEN
        -- 如果从完成状态变为其他状态，需要回滚余额
        IF OLD.status = 'COMPLETED' AND NEW.status != 'COMPLETED' THEN
            UPDATE users SET balance = balance + OLD.amount WHERE id = OLD.from_player_id;
            UPDATE users SET balance = balance - OLD.amount WHERE id = OLD.to_player_id;
        END IF;
        
        -- 如果从其他状态变为完成状态，需要更新余额
        IF OLD.status != 'COMPLETED' AND NEW.status = 'COMPLETED' THEN
            UPDATE users SET balance = balance - NEW.amount WHERE id = NEW.from_player_id;
            UPDATE users SET balance = balance + NEW.amount WHERE id = NEW.to_player_id;
        END IF;
        
        -- 记录状态变更日志
        INSERT INTO system_configs (config_key, config_value, description, config_type)
        VALUES (
            CONCAT('transaction_status_change_', NEW.id::text),
            json_build_object(
                'transaction_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'changed_at', NOW()
            ),
            '交易状态变更记录',
            'JSON'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_transactions_after_update
AFTER UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION transactions_after_update();

-- ==========================================
-- 结算结果相关触发器
-- ==========================================

-- 结算结果创建后更新用户统计
DROP TRIGGER IF EXISTS tr_settlement_results_after_insert ON settlement_results;

CREATE OR REPLACE FUNCTION settlement_results_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    game_result TEXT;
BEGIN
    -- 根据结算结果确定游戏结果
    IF NEW.is_winner THEN
        game_result := 'WIN';
    ELSIF NEW.final_balance = 0 THEN
        game_result := 'DRAW';
    ELSE
        game_result := 'LOSS';
    END IF;
    
    -- 更新用户游戏统计
    PERFORM update_user_stats(
        NEW.user_id, 
        game_result, 
        NEW.final_balance, 
        NEW.total_received - NEW.total_transferred
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_settlement_results_after_insert
AFTER INSERT ON settlement_results
FOR EACH ROW
EXECUTE FUNCTION settlement_results_after_insert();

-- ==========================================
-- 系统配置相关触发器
-- ==========================================

-- 系统配置更新记录
DROP TRIGGER IF EXISTS tr_system_configs_after_update ON system_configs;

CREATE OR REPLACE FUNCTION system_configs_after_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Avoid recursive triggers (config history doesn't need its own history)
    IF OLD.config_key NOT LIKE 'config_history_%' AND OLD.config_key NOT LIKE '%_deleted_%' THEN
        -- Record configuration change history
        INSERT INTO system_configs (config_key, config_value, description, config_type)
        VALUES (
            'config_history_' || OLD.config_key || '_' || (EXTRACT(EPOCH FROM NOW()))::text,
            json_build_object(
                'config_key', OLD.config_key,
                'old_value', OLD.config_value,
                'new_value', NEW.config_value,
                'changed_at', NOW()
            ),
            '配置变更历史记录',
            'JSON'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_system_configs_after_update
AFTER UPDATE ON system_configs
FOR EACH ROW
EXECUTE FUNCTION system_configs_after_update();

-- ==========================================
-- 数据完整性检查触发器
-- ==========================================

-- 交易金额检查
DROP TRIGGER IF EXISTS tr_transactions_before_insert ON transactions;

CREATE OR REPLACE FUNCTION transactions_before_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if amount is positive
    IF NEW.amount <= 0 THEN
        RAISE EXCEPTION 'Transaction amount must be positive';
    END IF;
    
    -- Check if sender and receiver are different
    IF NEW.from_player_id = NEW.to_player_id THEN
        RAISE EXCEPTION 'From player and to player cannot be the same';
    END IF;
    
    -- Check if room is active (except for settlement transactions)
    IF NEW.type != 'SETTLEMENT' THEN
        IF NOT EXISTS (SELECT 1 FROM rooms WHERE id = NEW.room_id AND status = 'ACTIVE') THEN
            RAISE EXCEPTION 'Room is not active';
        END IF;
    END IF;
    
    -- Check if users are in the room
    IF NOT EXISTS (SELECT 1 FROM room_members WHERE room_id = NEW.room_id AND user_id = NEW.from_player_id AND left_at IS NULL) THEN
        RAISE EXCEPTION 'From player is not in the room';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM room_members WHERE room_id = NEW.room_id AND user_id = NEW.to_player_id AND left_at IS NULL) THEN
        RAISE EXCEPTION 'To player is not in the room';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_transactions_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION transactions_before_insert();

-- 房间成员数量检查
DROP TRIGGER IF EXISTS tr_room_members_before_insert ON room_members;

CREATE OR REPLACE FUNCTION room_members_before_insert()
RETURNS TRIGGER AS $$
DECLARE
    current_members INT;
    max_members INT;
BEGIN
    -- Get room's max members and current member count
    SELECT max_players INTO max_members FROM rooms WHERE id = NEW.room_id;
    SELECT COUNT(*) INTO current_members FROM room_members 
    WHERE room_id = NEW.room_id AND left_at IS NULL;
    
    -- Check if room is full
    IF current_members >= max_members THEN
        RAISE EXCEPTION 'Room is full';
    END IF;
    
    -- Check if user is already in the room
    IF EXISTS (SELECT 1 FROM room_members 
              WHERE room_id = NEW.room_id 
              AND user_id = NEW.user_id 
              AND left_at IS NULL) THEN
        RAISE EXCEPTION 'User is already in the room';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_room_members_before_insert
BEFORE INSERT ON room_members
FOR EACH ROW
EXECUTE FUNCTION room_members_before_insert();


-- ==========================================
-- 完成提示
-- ==========================================
SELECT 'Triggers created successfully!' AS message; 