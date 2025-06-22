-- ==========================================
-- 游戏记账系统示例场景数据
-- 创建时间: 2024-01-XX
-- 数据库类型: PostgreSQL 12+
-- 演示各种业务场景的完整数据流
-- ==========================================

-- 设置时区
SET TIMEZONE = 'Asia/Shanghai';

-- ==========================================
-- 场景1: 德州扑克现金局完整流程
-- ==========================================

-- 清理演示数据
DELETE FROM settlement_results WHERE room_id LIKE 'demo_%';
DELETE FROM transactions WHERE room_id LIKE 'demo_%';
DELETE FROM room_members WHERE room_id LIKE 'demo_%';
DELETE FROM rooms WHERE id LIKE 'demo_%';
DELETE FROM users WHERE id LIKE 'demo_%';

-- 创建演示用户
INSERT INTO users (id, name, avatar, phone, email, balance, is_host, status, created_at) VALUES
('demo_user_001', 'Alex Chen', 'https://api.dicebear.com/7.x/avataaars/svg?seed=alex', '13900000001', 'alex@demo.com', 0.00, TRUE, 'ACTIVE', NOW() - INTERVAL 1 HOUR),
('demo_user_002', 'Bob Wang', 'https://api.dicebear.com/7.x/avataaars/svg?seed=bob', '13900000002', 'bob@demo.com', 0.00, FALSE, 'ACTIVE', NOW() - INTERVAL 1 HOUR),
('demo_user_003', 'Carol Li', 'https://api.dicebear.com/7.x/avataaars/svg?seed=carol', '13900000003', 'carol@demo.com', 0.00, FALSE, 'ACTIVE', NOW() - INTERVAL 1 HOUR),
('demo_user_004', 'David Zhang', 'https://api.dicebear.com/7.x/avataaars/svg?seed=david', '13900000004', 'david@demo.com', 0.00, FALSE, 'ACTIVE', NOW() - INTERVAL 1 HOUR),
('demo_user_005', 'Eva Liu', 'https://api.dicebear.com/7.x/avataaars/svg?seed=eva', '13900000005', 'eva@demo.com', 0.00, FALSE, 'ACTIVE', NOW() - INTERVAL 1 HOUR),
('demo_user_006', 'Frank Wu', 'https://api.dicebear.com/7.x/avataaars/svg?seed=frank', '13900000006', 'frank@demo.com', 0.00, FALSE, 'ACTIVE', NOW() - INTERVAL 1 HOUR);

-- 创建德州扑克房间
INSERT INTO rooms (id, name, host_id, room_code, max_players, status, settings, created_at) VALUES
('demo_room_001', 'Alex德州扑克现金局', 'demo_user_001', 'DEMO01', 6, 'ACTIVE', 
 '{
     "allowNegativeBalance": false,
     "autoSettle": false,
     "maxTransactionAmount": 5000,
     "transactionTypes": ["TRANSFER", "EXPENSE"],
     "gameType": "poker",
     "blinds": {"small": 5, "big": 10},
     "buyInMin": 200,
     "buyInMax": 1000
 }'::jsonb, 
 NOW() - INTERVAL '50 minutes');

-- 玩家加入房间
INSERT INTO room_members (id, room_id, user_id, nickname, role, joined_at) VALUES
('demo_member_001', 'demo_room_001', 'demo_user_001', 'Alex', 'HOST', NOW() - INTERVAL '50 minutes'),
('demo_member_002', 'demo_room_001', 'demo_user_002', 'Bob', 'MEMBER', NOW() - INTERVAL '45 minutes'),
('demo_member_003', 'demo_room_001', 'demo_user_003', 'Carol', 'MEMBER', NOW() - INTERVAL '40 minutes'),
('demo_member_004', 'demo_room_001', 'demo_user_004', 'David', 'MEMBER', NOW() - INTERVAL '35 minutes'),
('demo_member_005', 'demo_room_001', 'demo_user_005', 'Eva', 'MEMBER', NOW() - INTERVAL '30 minutes'),
('demo_member_006', 'demo_room_001', 'demo_user_006', 'Frank', 'MEMBER', NOW() - INTERVAL '25 minutes');

-- 买入筹码（初始资金）
INSERT INTO transactions (id, room_id, from_player_id, to_player_id, amount, description, type, status, metadata, created_at) VALUES
('demo_trans_001', 'demo_room_001', 'demo_user_001', 'demo_user_001', 500.00, 'Alex买入筹码', 'TRANSFER', 'COMPLETED', JSON_OBJECT('action', 'buy_in', 'chips', 500), NOW() - INTERVAL 45