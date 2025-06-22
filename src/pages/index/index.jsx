import { useState, useEffect } from 'react'
import { View, Button as TaroButton } from '@tarojs/components'
import PlayerAvatar from '../../components/player-avatar.js'
import GameStatsDisplay from '../../components/game-stats.js'
import QRCodeModal from '../../components/qr-code-modal.js'
import PlayerProfileModal from '../../components/player-profile-modal.js'
import SpendingLimitModal from '../../components/spending-limit-modal.js'
import GameSettlement from '../../components/game-settlement.js'
import TransferModal from '../../components/transfer-modal.js'
import TransactionHistory from '../../components/transaction-history.js'
import { useCurrentUser, useUsers, useRoom, useTransactions, useGameStats, useCreateTransaction } from '../../hooks/useGraphQL.js'
import { GameService } from '../../services/gameService.js'
// ... 其他必要的 import ...

export default function Index() {
  const [currentView, setCurrentView] = useState('room') // 默认显示房间视图
  const [showQRModal, setShowQRModal] = useState(false)
  const [showProfileModal, setShowProfileModal] = useState(false)
  const [showSpendingModal, setShowSpendingModal] = useState(false)
  const [showTransferModal, setShowTransferModal] = useState(false)
  const [currentRoomId] = useState('room-1') // 当前房间ID

  // 使用GraphQL hooks获取数据
  const { data: currentUserData, loading: userLoading } = useCurrentUser()
  const { data: usersData, loading: usersLoading, refetch: refetchUsers } = useUsers()
  const { data: roomData, loading: roomLoading, refetch: refetchRoom } = useRoom(currentRoomId)
  const { data: transactionsData, loading: transactionsLoading, refetch: refetchTransactions } = useTransactions(currentRoomId)
  const { data: gameStatsData, loading: statsLoading } = useGameStats(currentUserData?.currentUser?.id)
  const [createTransaction] = useCreateTransaction()

  // 从GraphQL数据中提取值
  const currentPlayer = currentUserData?.currentUser
  const roomPlayers = roomData?.room?.players || []
  const transactions = transactionsData?.transactions || []
  const gameStats = gameStatsData?.gameStats || {
    wins: 0,
    losses: 0,
    winRate: 0,
    totalPoints: 0,
    friendRanking: 0,
  }

  // 数据加载状态
  if (userLoading || usersLoading || roomLoading || transactionsLoading) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg">正在加载...</View>
      </View>
    )
  }

  if (currentView === 'settlement') {
    return (
      <GameSettlement
        totalScore={0}
        onGenerateStrategy={() => {}}
        onExitRoom={() => setCurrentView('profile')}
        onViewSettlement={() => {}}
        onViewRanking={() => {}}
        onViewHistory={() => {}}
        onViewManual={() => {}}
      />
    )
  }

  if (currentView === 'room') {
    return (
      <View className="min-h-screen bg-gray-50">
        {/* Header */}
        <View className="bg-white border-b p-4 flex items-center justify-between">
          <View className="flex items-center space-x-2">
            <View className="text-lg font-semibold">打牌记账 jyyj 房间</View>
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
              <View key={player.id} className="w-20 text-center">
                <TaroButton onClick={() => setShowProfileModal(true)} className="flex flex-col items-center space-y-2 w-full">
                  <PlayerAvatar name={player.name} size="lg" />
                  <View className="text-xs font-medium truncate w-full">{player.name}</View>
                  <View className="text-sm font-bold text-orange-500">¥{player.balance}</View>
                </TaroButton>
              </View>
            ))}
            {/* Add Friend Button */}
            <View className="w-20 text-center">
              <TaroButton onClick={() => setShowSpendingModal(true)} className="flex flex-col items-center space-y-2 w-full">
                <View className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center" />
                <View className="text-xs truncate w-full">茶/饭(0)</View>
                <View className="text-sm font-bold text-orange-500">¥0</View>
              </TaroButton>
            </View>
            <View className="w-20 text-center">
              <TaroButton className="flex flex-col items-center space-y-2 w-full">
                <View className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center" />
                <View className="text-xs truncate w-full">添加好友</View>
              </TaroButton>
            </View>
          </View>
          {/* Transaction History */}
          <View className="mb-4">
            <TransactionHistory transactions={transactions} players={roomPlayers} />
          </View>
          {/* Transfer Button */}
          <View className="flex justify-center mb-4">
            <TaroButton onClick={() => setShowTransferModal(true)} className="bg-green-500 hover:bg-green-600 px-8">
              转账记分
            </TaroButton>
          </View>
          {/* Bottom Actions */}
          <View className="flex justify-center space-x-4">
            <TaroButton onClick={() => setCurrentView('settlement')} className="bg-orange-500 hover:bg-orange-600">
              结算
            </TaroButton>
            <TaroButton>客服</TaroButton>
            <TaroButton>我的</TaroButton>
          </View>
        </View>
        {/* Modals */}
        <PlayerProfileModal
          isOpen={showProfileModal}
          onClose={() => setShowProfileModal(false)}
          player={currentPlayer}
          onUpdateNickname={() => {}}
          onExitRoom={() => {
            setShowProfileModal(false)
            setCurrentView('profile')
          }}
        />
        <SpendingLimitModal
          isOpen={showSpendingModal}
          onClose={() => setShowSpendingModal(false)}
          onConfirm={() => setShowSpendingModal(false)}
        />
        <TransferModal
          isOpen={showTransferModal}
          onClose={() => setShowTransferModal(false)}
          players={roomPlayers || []}
          currentPlayer={currentPlayer}
          onTransfer={async (fromId, toId, amount, description) => {
            try {
              await createTransaction({
                input: {
                  fromPlayerId: fromId,
                  toPlayerId: toId,
                  amount: parseFloat(amount),
                  description: description || '转账',
                  type: 'TRANSFER',
                  roomId: currentRoomId
                }
              })
              
              // 刷新数据
              await Promise.all([
                refetchUsers(),
                refetchRoom(),
                refetchTransactions()
              ])
              
              setShowTransferModal(false)
            } catch (error) {
              console.error('转账失败:', error)
              // 这里可以显示错误提示
            }
          }}
        />
      </View>
    )
  }

  return (
    <View className="min-h-screen bg-gray-50">
      {/* Header */}
      <View className="bg-white border-b p-4 flex items-center justify-between">
        <View className="text-lg font-semibold">打牌记账</View>
      </View>
      {/* Profile Section */}
      <View className="bg-white p-6 text-center">
        <PlayerAvatar name={currentPlayer.name} size="lg" />
        <View className="text-xl font-semibold mt-3 mb-2">{currentPlayer.name}</View>
        <GameStatsDisplay stats={gameStats} />
        {/* Game Record */}
        <View className="flex items-center justify-center space-x-4 text-sm mb-6">
          <View>赢<View className="text-orange-500 font-semibold">2</View>次</View>
          <View>/</View>
          <View>输<View className="text-orange-500 font-semibold">1</View>次</View>
          <View>/</View>
          <View>胜率<View className="text-orange-500 font-semibold">66.67%</View></View>
          <View className="text-muted-foreground">战绩 &gt;</View>
        </View>
      </View>
      {/* Action Buttons */}
      <View className="p-4 space-y-4">
        <View className="grid grid-cols-2 gap-4">
          <TaroButton onClick={() => setCurrentView('room')} className="bg-orange-500 hover:bg-orange-600 h-12">
            我要开房
          </TaroButton>
          <TaroButton
            onClick={() => setShowQRModal(true)}
            className="h-12 border-orange-500 text-orange-500"
          >
            扫码进房
          </TaroButton>
        </View>
        {/* Bottom Navigation */}
        <View className="flex justify-center space-x-4 pt-4">
          <TaroButton>客服</TaroButton>
          <TaroButton>获取头像昵称</TaroButton>
          <TaroButton>使用手册</TaroButton>
        </View>
      </View>
      {/* QR Code Modal */}
      <QRCodeModal isOpen={showQRModal} onClose={() => setShowQRModal(false)} roomId="jyyj" />
    </View>
  )
}
