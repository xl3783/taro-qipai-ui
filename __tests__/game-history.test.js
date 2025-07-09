import { render, screen } from '@testing-library/react';
import GameHistory from '../src/pages/game-history/game-history';

// Mock the hook
jest.mock('../src/hooks/useGameHistoryViewModel', () => ({
  useGameHistoryViewModel: () => ({
    rooms: [
      {
        id: 'room-1',
        name: '测试房间1',
        status: 'ACTIVE',
        hostId: 'user-1',
        hostName: '张三',
        playerCount: 4,
        totalAmount: 1200,
        createdAt: '2024-01-15T10:00:00Z',
        updatedAt: '2024-01-15T12:30:00Z',
      },
      {
        id: 'room-2',
        name: '测试房间2',
        status: 'SETTLED',
        hostId: 'user-2',
        hostName: '李四',
        playerCount: 3,
        totalAmount: 800,
        createdAt: '2024-01-10T14:00:00Z',
        updatedAt: '2024-01-10T18:00:00Z',
      }
    ],
    stats: {
      totalRooms: 2,
      activeRooms: 1,
      settledRooms: 1,
      totalAmount: 2000,
      winRate: 50,
    },
    loading: false,
    error: null,
    refreshing: false,
    handleRoomClick: jest.fn(),
    handleRefresh: jest.fn(),
    clearError: jest.fn(),
    formatTime: jest.fn(() => '今天'),
    getStatusText: jest.fn((status) => {
      switch (status) {
        case 'ACTIVE': return '进行中';
        case 'SETTLED': return '已结束';
        case 'CLOSED': return '已关闭';
        default: return '未知';
      }
    }),
    getStatusClass: jest.fn((status) => {
      switch (status) {
        case 'ACTIVE': return 'active';
        case 'SETTLED': return 'settled';
        case 'CLOSED': return 'closed';
        default: return '';
      }
    }),
  }),
}));

describe('GameHistory Component', () => {
  test('renders game history page with stats', () => {
    render(<GameHistory />);
    
    // 检查页面标题
    expect(screen.getByText('战绩记录')).toBeInTheDocument();
    
    // 检查统计信息
    expect(screen.getByText('2')).toBeInTheDocument(); // 总房间数
    expect(screen.getByText('1')).toBeInTheDocument(); // 进行中
    expect(screen.getByText('1')).toBeInTheDocument(); // 已结束
    expect(screen.getByText('¥2000')).toBeInTheDocument(); // 总金额
  });

  test('renders room list', () => {
    render(<GameHistory />);
    
    // 检查房间信息
    expect(screen.getByText('测试房间1')).toBeInTheDocument();
    expect(screen.getByText('测试房间2')).toBeInTheDocument();
    expect(screen.getByText('房主: 张三')).toBeInTheDocument();
    expect(screen.getByText('房主: 李四')).toBeInTheDocument();
    expect(screen.getByText('4人')).toBeInTheDocument();
    expect(screen.getByText('3人')).toBeInTheDocument();
  });

  test('renders status badges', () => {
    render(<GameHistory />);
    
    // 检查状态标签
    expect(screen.getByText('进行中')).toBeInTheDocument();
    expect(screen.getByText('已结束')).toBeInTheDocument();
  });

  test('renders empty state when no rooms', () => {
    // Mock empty rooms
    jest.doMock('../src/hooks/useGameHistoryViewModel', () => ({
      useGameHistoryViewModel: () => ({
        rooms: [],
        stats: {
          totalRooms: 0,
          activeRooms: 0,
          settledRooms: 0,
          totalAmount: 0,
          winRate: 0,
        },
        loading: false,
        error: null,
        refreshing: false,
        handleRoomClick: jest.fn(),
        handleRefresh: jest.fn(),
        clearError: jest.fn(),
        formatTime: jest.fn(),
        getStatusText: jest.fn(),
        getStatusClass: jest.fn(),
      }),
    }));

    render(<GameHistory />);
    
    expect(screen.getByText('暂无战绩记录')).toBeInTheDocument();
    expect(screen.getByText('开始创建房间或加入房间来记录你的战绩吧！')).toBeInTheDocument();
  });
}); 