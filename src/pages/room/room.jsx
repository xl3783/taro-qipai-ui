import { View, Button as TaroButton } from '@tarojs/components'
import Taro from '@tarojs/taro'
import PlayerAvatar from '../../components/player-avatar.js'
import PlayerProfileModal from '../../components/player-profile-modal.js'
import SpendingLimitModal from '../../components/spending-limit-modal.js'
import GameSettlement from '../../components/game-settlement.js'
import TransferModal from '../../components/transfer-modal.js'
import TransactionHistory from '../../components/transaction-history.js'
import { useRoomViewModel } from '../../hooks/useRoomViewModel.ts'
import './room.scss'

export default function Room() {
  // 获取页面参数
  const router = Taro.getCurrentInstance().router
  const roomId = router.params.roomId
  const roomName = router.params.roomName

  // 使用 MVVM Hook
  const {
    // 状态
    currentView,
    showProfileModal,
    showSpendingModal,
    showTransferModal,
    choosePlayerProfile,
    transactions,
    roomPlayers,
    loading,
    error,
    
    // 事件处理函数
    handleChoosePlayer,
    handleCloseProfileModal,
    handleShowTransferModal,
    handleCloseTransferModal,
    handleTransfer,
    handleSwitchToSettlement,
    handleExitRoom,
    clearError,
    
    // 获取数据的方法
    getCurrentUser,
    getPlayersForTransfer,
  } = useRoomViewModel(roomId, roomName);

  // 数据加载状态
  if (loading) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg">正在加载...</View>
      </View>
    )
  }

  // 错误状态
  if (error) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg text-red-500">加载失败: {error}</View>
        <TaroButton onClick={clearError} className="mt-4">重试</TaroButton>
      </View>
    )
  }

  if (currentView === 'settlement') {
    return (
      <GameSettlement
        roomId={roomId}
        roomName={roomName}
        participants={roomPlayers}
        totalScore={roomPlayers.reduce((sum, player) => sum + (player.finalScore || 0), 0)}
        onGenerateStrategy={() => {}}
        onExitRoom={handleExitRoom}
        onViewSettlement={() => {}}
        onViewRanking={() => {}}
        onViewHistory={() => {}}
        onViewManual={() => {}}
        onBackToRoom={handleSwitchToRoom}
        onSettlement={handleSettlement}
      />
    )
  }

  return (
    <View className="min-h-screen bg-gray-50">
      {/* Header */}
      <View className="bg-white border-b p-4 flex items-center justify-between">
        <View className="flex items-center gap-2">
          <View className="text-lg font-semibold">房间: {roomName}</View>
        </View>
      </View>
      {/* Notice Bar */}
      <View className="bg-orange-100 p-3 flex items-center justify-between">
        <View className="text-sm text-orange-700">退房/重开 需要先点结算归零数据</View>
      </View>
      {/* Players */}
      <View className="p-4">
        <View className="flex flex-wrap justify-center gap-4 mb-6">
          {roomPlayers.map((player) => (
            <View key={player.participationId} className="w-20 text-center">
              <TaroButton onClick={() => handleChoosePlayer(player)} className="flex flex-col items-center gap-2 w-full">
                <PlayerAvatar name={player.playerByPlayerId.username} size="lg" />
                <View className="text-xs font-medium truncate w-full">{player.playerByPlayerId.username}</View>
                <View className="text-sm font-bold text-orange-500">¥{player.finalScore}</View>
              </TaroButton>
            </View>
          ))}
          <View className="w-20 text-center">
            <TaroButton className="flex flex-col items-center gap-2 w-full">
              <View className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center" />
              <View className="text-xs truncate w-full">添加好友</View>
            </TaroButton>
          </View>
        </View>
        {/* Transaction History */}
        <View className="mb-4">
          <TransactionHistory transactions={transactions} />
        </View>
        {/* Transfer Button */}
        <View className="flex justify-center mb-4">
          <TaroButton 
            onClick={handleShowTransferModal} 
            className="bg-green-500 px-8"
            hoverClass="hover-bg-green-600"
          >
            转账
          </TaroButton>
        </View>
        {/* Bottom Actions */}
        <View className="flex justify-center gap-4">
          <TaroButton 
            onClick={handleSwitchToSettlement} 
            className="bg-orange-500"
            hoverClass="hover-bg-orange-600"
          >
            结算
          </TaroButton>
          {/* <TaroButton>客服</TaroButton> */}
          <TaroButton onClick={handleExitRoom}>退房</TaroButton>
        </View>
      </View>
      {/* Modals */}
      <PlayerProfileModal
        isOpen={showProfileModal}
        onClose={handleCloseProfileModal}
        player={choosePlayerProfile}
        onUpdateNickname={() => {}}
        onExitRoom={handleExitRoom}
      />
      <SpendingLimitModal
        isOpen={showSpendingModal}
        onClose={() => {}}
        onConfirm={() => {}}
      />
      <TransferModal
        isOpen={showTransferModal}
        onClose={handleCloseTransferModal}
        players={roomPlayers.map(player => ({
          id: player.playerId,
          username: player.playerByPlayerId.username,
          avatarUrl: player.playerByPlayerId.avatarUrl
        }))}
        currentPlayer={getCurrentUser()}
        onTransfer={handleTransfer}
      />
    </View>
  )
} 