import { useState, useEffect } from "react";
import Taro from "@tarojs/taro";
import { IndexPageModel } from "../models/IndexPageModel";
import { 
  IndexPageState, 
  UserInfo, 
  GameStats, 
  LoginResponse, 
  WechatUserInfo 
} from "../types/index";
import { GraphQLService } from "../services/GraphQLService";

export class IndexPageViewModel {
  private model: IndexPageModel;
  private state: IndexPageState;
  private setState: React.Dispatch<React.SetStateAction<IndexPageState>>;

  constructor(
    model: IndexPageModel,
    state: IndexPageState,
    setState: React.Dispatch<React.SetStateAction<IndexPageState>>
  ) {
    this.model = model;
    this.state = state;
    this.setState = setState;
  }

  /**
   * 初始化页面
   */
  async initialize(): Promise<void> {
    try {
      await this.doLogin();
    } catch (error) {
      console.error("页面初始化失败:", error);
    }
  }

  /**
   * 执行登录流程
   */
  async doLogin(): Promise<void> {
    try {
      this.setState(prev => ({ ...prev, isLoggingIn: true }));

      await this.model.wechatLogin();

      // const token = await this.model.getToken();
      // if (!token) {
        // 执行微信登录
        // const loginResponse = await this.model.wechatLogin();
        // await this.model.setToken(loginResponse.token);
        
        // 更新游戏统计
        this.setState(prev => ({
          ...prev,
          gameStats: {
            ...prev.gameStats,
            // totalPoints: loginResponse.score,
          }
      }));
      // }

      // 获取用户档案
      const userProfile = await GraphQLService.getPlayerProfile();
      // const userInfo: UserInfo = {
      //   username: userProfile.username,
      //   avatarUrl: userProfile.avatarUrl,
      //   playerId: userProfile.playerId,
      // };

      // this.setState(prev => ({
      //   ...prev,
      //   userInfo,
      //   loginData: userProfile as LoginResponse,
      // }));

      console.log("登录成功:", userProfile);
    } catch (error) {
      console.error("登录失败:", error);
    } finally {
      this.setState(prev => ({ ...prev, isLoggingIn: false }));
    }
  }

  /**
   * 获取微信用户信息
   */
  async handleGetUserProfile(): Promise<void> {
    try {
      const wxUserInfo = await this.model.getWechatUserInfo();
      await this.model.setUserInfo(wxUserInfo);
      
      const userInfo: UserInfo = {
        username: wxUserInfo.nickName,
        avatarUrl: wxUserInfo.avatarUrl,
        playerId: this.state.userInfo?.playerId || "unknown",
      };

      this.setState(prev => ({ ...prev, userInfo }));
    } catch (error) {
      console.error("获取用户信息失败:", error);
    }
  }

  /**
   * 创建房间
   */
  handleCreateRoom(): void {
    Taro.navigateTo({
      url: "/pages/room/room",
    });
  }

  /**
   * 加入房间
   */
  handleJoinRoom(): void {
    this.setState(prev => ({ ...prev, showQRModal: true }));
  }

  /**
   * 关闭二维码模态框
   */
  handleCloseQRModal(): void {
    this.setState(prev => ({ ...prev, showQRModal: false }));
  }

  /**
   * 二维码扫描成功
   */
  handleQRCodeScanned(roomId: string): void {
    this.setState(prev => ({ ...prev, showQRModal: false }));
    // 扫码成功后跳转到房间页面
    Taro.navigateTo({
      url: `/pages/room/room?roomId=${roomId}`,
    });
  }

  /**
   * 获取当前状态
   */
  getState(): IndexPageState {
    return this.state;
  }

  /**
   * 检查是否正在加载
   */
  isLoading(): boolean {
    return this.state.isLoggingIn;
  }

  /**
   * 获取用户信息
   */
  getUserInfo(): UserInfo | null {
    return this.state.userInfo;
  }

  /**
   * 获取游戏统计
   */
  getGameStats(): GameStats {
    return this.state.gameStats;
  }

  /**
   * 获取二维码模态框状态
   */
  getQRModalState(): boolean {
    return this.state.showQRModal;
  }
} 