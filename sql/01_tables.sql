-- ==========================================
-- 游戏记账系统数据库表结构创建脚本
-- 创建时间: 2024-01-XX
-- 数据库类型: PostgreSQL 12+
-- ==========================================

-- 设置时区
SET TIMEZONE = 'Asia/Shanghai';

-- 创建枚举类型
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'BANNED');
CREATE TYPE room_status AS ENUM ('ACTIVE', 'SETTLED', 'CLOSED');
CREATE TYPE member_role AS ENUM ('HOST', 'MEMBER', 'OBSERVER');
CREATE TYPE transaction_type AS ENUM ('TRANSFER', 'EXPENSE', 'SETTLEMENT', 'ADJUSTMENT');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'COMPLETED', 'CANCELLED');
CREATE TYPE config_type AS ENUM ('STRING', 'NUMBER', 'BOOLEAN', 'JSON');

-- ==========================================
-- 1. 用户表 (users)
-- 存储用户基本信息
-- ==========================================
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    avatar VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    balance NUMERIC(10,2) DEFAULT 0.00,
    is_host BOOLEAN DEFAULT FALSE,
    status user_status DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_users_name ON users (name);
CREATE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_users_status ON users (status);
CREATE INDEX idx_users_created_at ON users (created_at);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为用户表创建更新触发器
CREATE TRIGGER tr_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 2. 房间表 (rooms)  
-- 存储游戏房间信息
-- ==========================================
CREATE TABLE rooms (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    host_id VARCHAR(50) NOT NULL,
    room_code VARCHAR(20) UNIQUE,
    max_players INT DEFAULT 20,
    status room_status DEFAULT 'ACTIVE',
    settings JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    
    FOREIGN KEY (host_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 创建索引
CREATE INDEX idx_rooms_host_id ON rooms (host_id);
CREATE INDEX idx_rooms_status ON rooms (status);
CREATE INDEX idx_rooms_room_code ON rooms (room_code);
CREATE INDEX idx_rooms_created_at ON rooms (created_at);

-- 为房间表创建更新触发器
CREATE TRIGGER tr_rooms_updated_at 
    BEFORE UPDATE ON rooms 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 3. 房间成员表 (room_members)
-- 存储房间成员关系
-- ==========================================
CREATE TABLE room_members (
    id VARCHAR(50) PRIMARY KEY,
    room_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    nickname VARCHAR(100),
    role member_role DEFAULT 'MEMBER',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP NULL,
    
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (room_id, user_id)
);

-- 创建索引
CREATE INDEX idx_room_members_room_id ON room_members (room_id);
CREATE INDEX idx_room_members_user_id ON room_members (user_id);
CREATE INDEX idx_room_members_joined_at ON room_members (joined_at);

-- ==========================================
-- 4. 交易记录表 (transactions)
-- 存储所有交易记录
-- ==========================================
CREATE TABLE transactions (
    id VARCHAR(50) PRIMARY KEY,
    room_id VARCHAR(50) NOT NULL,
    from_player_id VARCHAR(50) NOT NULL,
    to_player_id VARCHAR(50) NOT NULL,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    type transaction_type NOT NULL,
    status transaction_status DEFAULT 'COMPLETED',
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (from_player_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_player_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 创建索引
CREATE INDEX idx_transactions_room_id ON transactions (room_id);
CREATE INDEX idx_transactions_from_player ON transactions (from_player_id);
CREATE INDEX idx_transactions_to_player ON transactions (to_player_id);
CREATE INDEX idx_transactions_type ON transactions (type);
CREATE INDEX idx_transactions_status ON transactions (status);
CREATE INDEX idx_transactions_created_at ON transactions (created_at);

-- 为交易表创建更新触发器
CREATE TRIGGER tr_transactions_updated_at 
    BEFORE UPDATE ON transactions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 5. 游戏统计表 (game_stats)
-- 存储用户游戏统计数据
-- ==========================================
CREATE TABLE game_stats (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    total_games INT DEFAULT 0,
    wins INT DEFAULT 0 CHECK (wins >= 0),
    losses INT DEFAULT 0 CHECK (losses >= 0),
    draws INT DEFAULT 0 CHECK (draws >= 0),
    win_rate NUMERIC(5,2) DEFAULT 0.00 CHECK (win_rate >= 0 AND win_rate <= 100),
    total_points NUMERIC(10,2) DEFAULT 0.00,
    total_earnings NUMERIC(10,2) DEFAULT 0.00,
    total_losses NUMERIC(10,2) DEFAULT 0.00,
    friend_ranking INT DEFAULT 0,
    last_game_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user_id)
);

-- 创建索引
CREATE INDEX idx_game_stats_total_points ON game_stats (total_points);
CREATE INDEX idx_game_stats_win_rate ON game_stats (win_rate);
CREATE INDEX idx_game_stats_last_game_at ON game_stats (last_game_at);

-- 为游戏统计表创建更新触发器
CREATE TRIGGER tr_game_stats_updated_at 
    BEFORE UPDATE ON game_stats 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 6. 结算结果表 (settlement_results)
-- 存储房间结算结果
-- ==========================================
CREATE TABLE settlement_results (
    id VARCHAR(50) PRIMARY KEY,
    room_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    final_balance NUMERIC(10,2) NOT NULL,
    total_transferred NUMERIC(10,2) DEFAULT 0.00,
    total_received NUMERIC(10,2) DEFAULT 0.00,
    settlement_rank INT,
    is_winner BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (room_id, user_id)
);

-- 创建索引
CREATE INDEX idx_settlement_results_room_id ON settlement_results (room_id);
CREATE INDEX idx_settlement_results_user_id ON settlement_results (user_id);
CREATE INDEX idx_settlement_results_final_balance ON settlement_results (final_balance);
CREATE INDEX idx_settlement_results_created_at ON settlement_results (created_at);

-- ==========================================
-- 7. 系统配置表 (system_configs)
-- 存储系统配置信息
-- ==========================================
CREATE TABLE system_configs (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT,
    description VARCHAR(500),
    config_type config_type DEFAULT 'STRING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_system_configs_config_key ON system_configs (config_key);

-- 为系统配置表创建更新触发器
CREATE TRIGGER tr_system_configs_updated_at 
    BEFORE UPDATE ON system_configs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- 视图定义
-- ==========================================

-- 房间成员视图 (包含用户信息)
CREATE VIEW v_room_members AS
SELECT 
    rm.id,
    rm.room_id,
    rm.user_id,
    rm.nickname,
    rm.role,
    rm.joined_at,
    rm.left_at,
    u.name as user_name,
    u.avatar as user_avatar,
    u.balance as user_balance,
    u.status as user_status
FROM room_members rm
JOIN users u ON rm.user_id = u.id;

-- 交易详情视图 (包含用户和房间信息)
CREATE VIEW v_transaction_details AS
SELECT 
    t.id,
    t.room_id,
    t.from_player_id,
    t.to_player_id,
    t.amount,
    t.description,
    t.type,
    t.status,
    t.metadata,
    t.created_at,
    r.name as room_name,
    u1.name as from_player_name,
    u2.name as to_player_name,
    u1.avatar as from_player_avatar,
    u2.avatar as to_player_avatar
FROM transactions t
JOIN rooms r ON t.room_id = r.id
JOIN users u1 ON t.from_player_id = u1.id
JOIN users u2 ON t.to_player_id = u2.id;

-- 用户排名视图
CREATE VIEW v_user_rankings AS
SELECT 
    u.id,
    u.name,
    u.avatar,
    gs.total_games,
    gs.wins,
    gs.losses,
    gs.draws,
    gs.win_rate,
    gs.total_points,
    gs.total_earnings,
    gs.total_losses,
    gs.last_game_at,
    RANK() OVER (ORDER BY gs.total_points DESC) as global_rank
FROM users u
LEFT JOIN game_stats gs ON u.id = gs.user_id
WHERE u.status = 'ACTIVE'
ORDER BY gs.total_points DESC;

-- 添加表注释
COMMENT ON TABLE users IS '用户基本信息表';
COMMENT ON TABLE rooms IS '游戏房间信息表';
COMMENT ON TABLE room_members IS '房间成员关系表';
COMMENT ON TABLE transactions IS '交易记录表';
COMMENT ON TABLE game_stats IS '用户游戏统计表';
COMMENT ON TABLE settlement_results IS '房间结算结果表';
COMMENT ON TABLE system_configs IS '系统配置表';

-- 添加列注释
COMMENT ON COLUMN users.id IS '用户唯一标识';
COMMENT ON COLUMN users.name IS '用户姓名';
COMMENT ON COLUMN users.avatar IS '头像URL';
COMMENT ON COLUMN users.phone IS '手机号';
COMMENT ON COLUMN users.email IS '邮箱';
COMMENT ON COLUMN users.balance IS '当前余额';
COMMENT ON COLUMN users.is_host IS '是否为房主';
COMMENT ON COLUMN users.status IS '用户状态';
COMMENT ON COLUMN users.created_at IS '创建时间';
COMMENT ON COLUMN users.updated_at IS '更新时间';

-- ==========================================
-- 完成提示
-- ==========================================
SELECT 'Tables created successfully!' AS message; 