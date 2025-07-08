// 用户信息类型
export interface UserInfo {
  username: string;
  avatarUrl?: string;
  playerId: string;
}

// 微信用户信息类型
export interface WechatUserInfo {
  nickName: string;
  avatarUrl: string;
  gender: number;
  country: string;
  province: string;
  city: string;
  language: string;
}

// 游戏统计数据类型
export interface GameStats {
  totalPoints: number;
  wins: number;
  losses: number;
  winRate: number;
  friendRanking: number;
}

export interface LoginUser {
  id: string;
  role: string;
  nickname: string;
}


// 登录响应数据类型
export interface LoginResponse {
  token: string;
  user: LoginUser;
}

// API响应类型
export interface ApiResponse<T = any> {
  data: T;
  code: number;
  message: string;
}

// 页面状态类型
export interface IndexPageState {
  userInfo: UserInfo | null;
  gameStats: GameStats;
  showQRModal: boolean;
  isLoggingIn: boolean;
  loginData: LoginResponse | null;
}

// Export database types
export * from './database';
export * from './database-utils'; 