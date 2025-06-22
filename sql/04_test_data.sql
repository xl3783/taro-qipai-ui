-- ==========================================
-- 游戏记账系统测试数据
-- 创建时间: 2024-01-XX
-- 数据库类型: PostgreSQL 12+
-- ==========================================

-- 设置时区
SET TIMEZONE = 'Asia/Shanghai';

-- ==========================================
-- 清理现有测试数据
-- ==========================================
DELETE FROM settlement_results;
DELETE FROM game_stats;
DELETE FROM transactions;
DELETE FROM room_members;
DELETE FROM rooms;
DELETE FROM users;
DELETE FROM system_configs;

-- ==========================================
-- 1. 用户测试数据
-- ==========================================
INSERT INTO users (id, name, avatar, phone, email, balance, is_host, status, created_at) VALUES
('user_001', '张三', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhangsan', '13800138001', 'zhangsan@example.com', 0.00, TRUE, 'ACTIVE', '2024-01-01 10:00:00'),
('user_002', '李四', 'https://api.dicebear.com/7.x/avataaars/svg?seed=lisi', '13800138002', 'lisi@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:05:00'),
('user_003', '王五', 'https://api.dicebear.com/7.x/avataaars/svg?seed=wangwu', '13800138003', 'wangwu@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:10:00'),
('user_004', '赵六', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhaoliu', '13800138004', 'zhaoliu@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:15:00'),
('user_005', '钱七', 'https://api.dicebear.com/7.x/avataaars/svg?seed=qianqi', '13800138005', 'qianqi@example.com', 0.00, TRUE, 'ACTIVE', '2024-01-01 10:20:00'),
('user_006', '孙八', 'https://api.dicebear.com/7.x/avataaars/svg?seed=sunba', '13800138006', 'sunba@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:25:00'),
('user_007', '周九', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhoujiu', '13800138007', 'zhoujiu@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:30:00'),
('user_008', '吴十', 'https://api.dicebear.com/7.x/avataaars/svg?seed=wushi', '13800138008', 'wushi@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:35:00'),
('user_009', '郑十一', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhengshiyi', '13800138009', 'zhengshiyi@example.com', 0.00, FALSE, 'INACTIVE', '2024-01-01 10:40:00'),
('user_010', '王十二', 'https://api.dicebear.com/7.x/avataaars/svg?seed=wangshier', '13800138010', 'wangshier@example.com', 0.00, FALSE, 'ACTIVE', '2024-01-01 10:45:00');

-- ==========================================
-- 2. 房间测试数据
-- ==========================================
INSERT INTO rooms (id, name, host_id, room_code, max_players, status, settings, created_at) VALUES
('room_001', '张三的德州扑克房', 'user_001', 'ABC123', 8, 'ACTIVE', 
 '{"allowNegativeBalance": false, "autoSettle": false, "maxTransactionAmount": 5000, "transactionTypes": ["TRANSFER", "EXPENSE"]}'::jsonb, 
 '2024-01-01 11:00:00'),
('room_002', '钱七的麻将房', 'user_005', 'DEF456', 4, 'ACTIVE', 
 '{"allowNegativeBalance": true, "autoSettle": true, "maxTransactionAmount": 1000, "transactionTypes": ["TRANSFER", "EXPENSE", "ADJUSTMENT"]}'::jsonb, 
 '2024-01-01 14:00:00'),
('room_003', '周末聚会', 'user_001', 'GHI789', 10, 'SETTLED', 
 '{"allowNegativeBalance": false, "autoSettle": false, "maxTransactionAmount": 2000, "transactionTypes": ["TRANSFER", "EXPENSE"]}'::jsonb, 
 '2024-01-01 19:00:00'),
('room_004', '测试房间', 'user_005', 'JKL012', 6, 'CLOSED', 
 '{"allowNegativeBalance": false, "autoSettle": false, "maxTransactionAmount": 3000, "transactionTypes": ["TRANSFER"]}'::jsonb, 
 '2024-01-02 09:00:00');

-- ==========================================
-- 3. 房间成员测试数据
-- ==========================================
INSERT INTO room_members (id, room_id, user_id, nickname, role, joined_at, left_at) VALUES
-- 房间1成员
('member_001', 'room_001', 'user_001', '房主张三', 'HOST', '2024-01-01 11:00:00', NULL),
('member_002', 'room_001', 'user_002', '李四', 'MEMBER', '2024-01-01 11:05:00', NULL),
('member_003', 'room_001', 'user_003', '王五', 'MEMBER', '2024-01-01 11:10:00', NULL),
('member_004', 'room_001', 'user_004', '赵六', 'MEMBER', '2024-01-01 11:15:00', NULL),
('member_005', 'room_001', 'user_006', '孙八', 'MEMBER', '2024-01-01 11:20:00', NULL),

-- 房间2成员
('member_006', 'room_002', 'user_005', '房主钱七', 'HOST', '2024-01-01 14:00:00', NULL),
('member_007', 'room_002', 'user_007', '周九', 'MEMBER', '2024-01-01 14:05:00', NULL),
('member_008', 'room_002', 'user_008', '吴十', 'MEMBER', '2024-01-01 14:10:00', NULL),
('member_009', 'room_002', 'user_010', '王十二', 'MEMBER', '2024-01-01 14:15:00', NULL),

-- 房间3成员（已结束）
('member_010', 'room_003', 'user_001', '张三', 'HOST', '2024-01-01 19:00:00', '2024-01-01 22:00:00'),
('member_011', 'room_003', 'user_002', '李四', 'MEMBER', '2024-01-01 19:05:00', '2024-01-01 22:00:00'),
('member_012', 'room_003', 'user_003', '王五', 'MEMBER', '2024-01-01 19:10:00', '2024-01-01 22:00:00'),
('member_013', 'room_003', 'user_004', '赵六', 'MEMBER', '2024-01-01 19:15:00', '2024-01-01 22:00:00'),

-- 房间4成员（已关闭）
('member_014', 'room_004', 'user_005', '钱七', 'HOST', '2024-01-02 09:00:00', '2024-01-02 09:30:00'),
('member_015', 'room_004', 'user_006', '孙八', 'MEMBER', '2024-01-02 09:05:00', '2024-01-02 09:30:00');

-- ==========================================
-- 4. 交易记录测试数据
-- ==========================================
INSERT INTO transactions (id, room_id, from_player_id, to_player_id, amount, description, type, status, metadata, created_at) VALUES
-- 房间1的交易记录
('trans_001', 'room_001', 'user_002', 'user_001', 100.00, '买入筹码', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker"}'::jsonb, '2024-01-01 11:30:00'),
('trans_002', 'room_001', 'user_003', 'user_001', 150.00, '买入筹码', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker"}'::jsonb, '2024-01-01 11:35:00'),
('trans_003', 'room_001', 'user_004', 'user_001', 200.00, '买入筹码', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker"}'::jsonb, '2024-01-01 11:40:00'),
('trans_004', 'room_001', 'user_006', 'user_001', 120.00, '买入筹码', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker"}'::jsonb, '2024-01-01 11:45:00'),
('trans_005', 'room_001', 'user_001', 'user_002', 50.00, '第1局输给李四', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker", "hand": "AA vs KK"}'::jsonb, '2024-01-01 12:00:00'),
('trans_006', 'room_001', 'user_003', 'user_004', 80.00, '第1局输给赵六', 'TRANSFER', 'COMPLETED', '{"round": 1, "game_type": "poker", "hand": "QQ vs AA"}'::jsonb, '2024-01-01 12:05:00'),
('trans_007', 'room_001', 'user_001', 'user_006', 30.00, '第2局输给孙八', 'TRANSFER', 'COMPLETED', '{"round": 2, "game_type": "poker", "hand": "AK vs 88"}'::jsonb, '2024-01-01 12:30:00'),
('trans_008', 'room_001', 'user_002', 'user_003', 40.00, '第2局输给王五', 'TRANSFER', 'COMPLETED', '{"round": 2, "game_type": "poker", "hand": "JJ vs AQ"}'::jsonb, '2024-01-01 12:35:00'),

-- 房间2的交易记录
('trans_009', 'room_002', 'user_007', 'user_005', 200.00, '麻将第1局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 1, 'game_type', 'mahjong', 'fan', 3), '2024-01-01 15:00:00'),
('trans_010', 'room_002', 'user_008', 'user_005', 100.00, '麻将第1局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 1, 'game_type', 'mahjong', 'fan', 1), '2024-01-01 15:00:00'),
('trans_011', 'room_002', 'user_010', 'user_005', 150.00, '麻将第1局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 1, 'game_type', 'mahjong', 'fan', 2), '2024-01-01 15:00:00'),
('trans_012', 'room_002', 'user_005', 'user_007', 100.00, '麻将第2局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 2, 'game_type', 'mahjong', 'fan', 2), '2024-01-01 15:30:00'),
('trans_013', 'room_002', 'user_008', 'user_007', 80.00, '麻将第2局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 2, 'game_type', 'mahjong', 'fan', 1), '2024-01-01 15:30:00'),
('trans_014', 'room_002', 'user_010', 'user_007', 120.00, '麻将第2局', 'TRANSFER', 'COMPLETED', JSON_OBJECT('round', 2, 'game_type', 'mahjong', 'fan', 2), '2024-01-01 15:30:00'),

-- 房间3的交易记录（已结算）
('trans_015', 'room_003', 'user_002', 'user_001', 300.00, '聚会消费', 'EXPENSE', 'COMPLETED', JSON_OBJECT('type', 'dinner', 'location', '餐厅'), '2024-01-01 20:00:00'),
('trans_016', 'room_003', 'user_003', 'user_001', 300.00, '聚会消费', 'EXPENSE', 'COMPLETED', JSON_OBJECT('type', 'dinner', 'location', '餐厅'), '2024-01-01 20:00:00'),
('trans_017', 'room_003', 'user_004', 'user_001', 300.00, '聚会消费', 'EXPENSE', 'COMPLETED', JSON_OBJECT('type', 'dinner', 'location', '餐厅'), '2024-01-01 20:00:00'),
('trans_018', 'room_003', 'user_001', 'user_002', 75.00, 'KTV费用分摊', 'SETTLEMENT', 'COMPLETED', JSON_OBJECT('type', 'ktv', 'total', 300), '2024-01-01 21:30:00'),
('trans_019', 'room_003', 'user_001', 'user_003', 75.00, 'KTV费用分摊', 'SETTLEMENT', 'COMPLETED', JSON_OBJECT('type', 'ktv', 'total', 300), '2024-01-01 21:30:00'),
('trans_020', 'room_003', 'user_001', 'user_004', 75.00, 'KTV费用分摊', 'SETTLEMENT', 'COMPLETED', JSON_OBJECT('type', 'ktv', 'total', 300), '2024-01-01 21:30:00'),

-- 一些待处理的交易
('trans_021', 'room_001', 'user_002', 'user_003', 60.00, '第3局待确认', 'TRANSFER', 'PENDING', JSON_OBJECT('round', 3, 'game_type', 'poker'), '2024-01-01 13:00:00'),
('trans_022', 'room_002', 'user_005', 'user_008', 90.00, '麻将第3局待确认', 'TRANSFER', 'PENDING', JSON_OBJECT('round', 3, 'game_type', 'mahjong'), '2024-01-01 16:00:00');

-- ==========================================
-- 5. 游戏统计测试数据
-- ==========================================
INSERT INTO game_stats (id, user_id, total_games, wins, losses, draws, win_rate, total_points, total_earnings, total_losses, friend_ranking, last_game_at, updated_at) VALUES
('stats_001', 'user_001', 25, 15, 8, 2, 60.00, 1250.00, 2800.00, 1550.00, 1, '2024-01-01 12:30:00', '2024-01-01 12:30:00'),
('stats_002', 'user_002', 18, 8, 9, 1, 44.44, 320.00, 1200.00, 880.00, 5, '2024-01-01 12:35:00', '2024-01-01 12:35:00'),
('stats_003', 'user_003', 22, 12, 7, 3, 54.55, 890.00, 1800.00, 910.00, 3, '2024-01-01 12:35:00', '2024-01-01 12:35:00'),
('stats_004', 'user_004', 20, 11, 6, 3, 55.00, 1120.00, 2100.00, 980.00, 2, '2024-01-01 12:05:00', '2024-01-01 12:05:00'),
('stats_005', 'user_005', 30, 18, 10, 2, 60.00, 1680.00, 3200.00, 1520.00, 1, '2024-01-01 16:00:00', '2024-01-01 16:00:00'),
('stats_006', 'user_006', 15, 6, 8, 1, 40.00, 180.00, 900.00, 720.00, 6, '2024-01-01 12:30:00', '2024-01-01 12:30:00'),
('stats_007', 'user_007', 12, 7, 4, 1, 58.33, 680.00, 1100.00, 420.00, 4, '2024-01-01 15:30:00', '2024-01-01 15:30:00'),
('stats_008', 'user_008', 10, 3, 6, 1, 30.00, -150.00, 400.00, 550.00, 8, '2024-01-01 15:30:00', '2024-01-01 15:30:00'),
('stats_009', 'user_009', 0, 0, 0, 0, 0.00, 0.00, 0.00, 0.00, 0, NULL, '2024-01-01 10:40:00'),
('stats_010', 'user_010', 8, 2, 5, 1, 25.00, -220.00, 300.00, 520.00, 9, '2024-01-01 15:30:00', '2024-01-01 15:30:00');

-- ==========================================
-- 6. 结算结果测试数据
-- ==========================================
INSERT INTO settlement_results (id, room_id, user_id, final_balance, total_transferred, total_received, settlement_rank, is_winner, created_at) VALUES
-- 房间3的结算结果
('settle_001', 'room_003', 'user_001', 675.00, 225.00, 900.00, 1, TRUE, '2024-01-01 22:00:00'),
('settle_002', 'room_003', 'user_002', -225.00, 375.00, 150.00, 4, FALSE, '2024-01-01 22:00:00'),
('settle_003', 'room_003', 'user_003', -225.00, 375.00, 150.00, 3, FALSE, '2024-01-01 22:00:00'),
('settle_004', 'room_003', 'user_004', -225.00, 375.00, 150.00, 2, FALSE, '2024-01-01 22:00:00');

-- ==========================================
-- 7. 系统配置测试数据
-- ==========================================
INSERT INTO system_configs (config_key, config_value, description, config_type, created_at) VALUES
('system_name', '游戏记账系统', '系统名称', 'STRING', '2024-01-01 00:00:00'),
('version', '1.0.0', '系统版本', 'STRING', '2024-01-01 00:00:00'),
('max_room_members', '20', '房间最大成员数', 'NUMBER', '2024-01-01 00:00:00'),
('default_transaction_limit', '10000', '默认交易限额', 'NUMBER', '2024-01-01 00:00:00'),
('enable_notifications', 'true', '是否启用通知', 'BOOLEAN', '2024-01-01 00:00:00'),
('supported_games', '["poker", "mahjong", "general"]', '支持的游戏类型', 'JSON', '2024-01-01 00:00:00'),
('currency_symbol', '¥', '货币符号', 'STRING', '2024-01-01 00:00:00'),
('timezone', 'Asia/Shanghai', '时区设置', 'STRING', '2024-01-01 00:00:00'),
('auto_backup_enabled', 'true', '是否启用自动备份', 'BOOLEAN', '2024-01-01 00:00:00'),
('backup_interval_hours', '24', '备份间隔（小时）', 'NUMBER', '2024-01-01 00:00:00');

-- PostgreSQL 默认启用外键检查

-- ==========================================
-- 数据验证查询
-- ==========================================

-- 验证用户数据
SELECT '用户数据验证' as check_type, COUNT(*) as count FROM users;

-- 验证房间数据
SELECT '房间数据验证' as check_type, COUNT(*) as count FROM rooms;

-- 验证房间成员数据
SELECT '房间成员数据验证' as check_type, COUNT(*) as count FROM room_members;

-- 验证交易数据
SELECT '交易数据验证' as check_type, COUNT(*) as count FROM transactions;

-- 验证统计数据
SELECT '统计数据验证' as check_type, COUNT(*) as count FROM game_stats;

-- 验证结算数据
SELECT '结算数据验证' as check_type, COUNT(*) as count FROM settlement_results;

-- 验证配置数据
SELECT '配置数据验证' as check_type, COUNT(*) as count FROM system_configs;

-- 显示房间状态统计
SELECT 
    '房间状态统计' as check_type,
    status,
    COUNT(*) as count
FROM rooms 
GROUP BY status;

-- 显示交易状态统计
SELECT 
    '交易状态统计' as check_type,
    status,
    COUNT(*) as count
FROM transactions 
GROUP BY status;

-- 显示用户余额统计
SELECT 
    '用户余额统计' as check_type,
    CASE 
        WHEN balance > 0 THEN '盈利'
        WHEN balance < 0 THEN '亏损'
        ELSE '平衡'
    END as balance_status,
    COUNT(*) as count
FROM users 
WHERE status = 'ACTIVE'
GROUP BY balance_status;

-- ==========================================
-- 完成提示
-- ==========================================
SELECT 'Test data inserted successfully!' AS message;
SELECT CONCAT('Total users: ', (SELECT COUNT(*) FROM users)) AS summary;
SELECT CONCAT('Total rooms: ', (SELECT COUNT(*) FROM rooms)) AS summary;
SELECT CONCAT('Total transactions: ', (SELECT COUNT(*) FROM transactions)) AS summary;