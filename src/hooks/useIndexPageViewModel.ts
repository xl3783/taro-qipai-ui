import { useState, useEffect, useCallback } from "react";
import { IndexPageModel } from "../models/IndexPageModel";
import { IndexPageViewModel } from "../viewmodels/IndexPageViewModel";
import { UserInfo } from "../types/index";

export const useIndexPageViewModel = () => {
  const [state, setState] = useState({
    userInfo: null as UserInfo | null,
    gameStats: {
      totalPoints: 0,
      wins: 0,
      losses: 0,
      winRate: '--',
      friendRanking: 0,
    },
    showQRModal: false,
    isLoggingIn: false,
    loginData: null,
  });

  const [viewModel] = useState(() => {
    const model = new IndexPageModel();
    return new IndexPageViewModel(model, state, setState);
  });

  // 初始化
  useEffect(() => {
    viewModel.initialize();
  }, []);

  // 创建事件处理函数
  const handleGetUserProfile = useCallback(async () => {
    await viewModel.handleGetUserProfile();
  }, [viewModel]);

  const handleCreateRoom = useCallback(() => {
    viewModel.handleCreateRoom();
  }, [viewModel]);

  const handleJoinRoom = useCallback((roomName: string) => {
    viewModel.handleJoinRoom(roomName);
  }, [viewModel]);

  const handleCloseQRModal = useCallback(() => {
    viewModel.handleCloseQRModal();
  }, [viewModel]);

  const handleQRCodeScanned = useCallback((roomId: string) => {
    viewModel.handleQRCodeScanned(roomId);
  }, [viewModel]);

  return {
    // 状态
    userInfo: state.userInfo,
    gameStats: state.gameStats,
    showQRModal: state.showQRModal,
    isLoggingIn: state.isLoggingIn,
    
    // 事件处理函数
    handleGetUserProfile,
    handleCreateRoom,
    handleJoinRoom,
    handleCloseQRModal,
    handleQRCodeScanned,
  };
}; 