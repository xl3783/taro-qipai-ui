import { useState, useEffect } from 'react'
import { View, Button as TaroButton } from '@tarojs/components'
import Taro from '@tarojs/taro'
import PlayerAvatar from '../../components/player-avatar.js'
import PlayerProfileModal from '../../components/player-profile-modal.js'
import SpendingLimitModal from '../../components/spending-limit-modal.js'
import GameSettlement from '../../components/game-settlement.js'
import TransferModal from '../../components/transfer-modal.js'
import TransactionHistory from '../../components/transaction-history.js'
import { useCurrentUser, useUsers, useRoom, useTransactions, useGameStats, useCreateTransaction } from '../../hooks/useGraphQL.js'
import { useQuery } from '../../hooks/useGraphQL.js'
import './room.scss'

export default function Room() {
  // 获取页面参数
  const router = Taro.getCurrentInstance().router
  const roomId = router.params.roomId || '1afc3bd7-8087-4dcf-905d-1dcd60d858ae'

  const GET_GAME_PARTICIPANTS = `
  query GetGameParticipants($gameId: String!) {
    allGameParticipants(condition: { gameId: $gameId }) {
      nodes {
        participationId,
        playerId,
        playerByPlayerId {
          username
          avatarUrl
        }
      }
    }
  }
`;

  const GET_PLAYER_TRANSACTIONS = `
query GetPlayerTransactions($gameId: String!) {
  allTransferRecords(condition: {gameId: $gameId}) {
    nodes {
      nodeId,
      transferId,
      fromPlayerId,
      toPlayerId,
      playerByFromPlayerId {
        username,
        avatarUrl
      },
      playerByToPlayerId {
        username,
         avatarUrl
      }
      points
    }
  }
}`;

  const { data: gameParticipantsData, loading: gameParticipantsLoading } = useQuery(GET_GAME_PARTICIPANTS, { gameId: roomId });
  const { data: playerTransactionsData, loading: playerTransactionsLoading } = useQuery(GET_PLAYER_TRANSACTIONS, { gameId: roomId });

  const [currentView, setCurrentView] = useState('room')
  const [showProfileModal, setShowProfileModal] = useState(false)
  const [showSpendingModal, setShowSpendingModal] = useState(false)
  const [showTransferModal, setShowTransferModal] = useState(false)
  const [currentRoomId] = useState(roomId)
  const [choosePlayerProfile, setChoosePlayerProfile] = useState(null)
  const [transactions, setTransactions] = useState([])

  // 使用GraphQL hooks获取数据
  const { data: currentUserData, loading: userLoading } = useCurrentUser()
  const { data: usersData, loading: usersLoading, refetch: refetchUsers } = useUsers()
  const { data: roomData, loading: roomLoading, refetch: refetchRoom } = useRoom(currentRoomId)
  const { data: transactionsData, loading: transactionsLoading, refetch: refetchTransactions } = useTransactions(currentRoomId)
  const [createTransaction] = useCreateTransaction()

  const currentPlayer = {
    playerId: "mock_openid_gp55mnaesqj",
    username: "mock_nickname",
    avatarUrl: null,
  }

  const roomPlayers = gameParticipantsData?.allGameParticipants?.nodes || []

  useEffect(() => {
    if (playerTransactionsData) {
      const transactions = playerTransactionsData?.allTransferRecords?.nodes.map((node) => {
        return {
          id: node.nodeId,
          fromPlayerId: node.fromPlayerId,
          toPlayerId: node.toPlayerId,
          fromPlayer: {
            username: node.playerByFromPlayerId.username,
            avatarUrl: node.playerByFromPlayerId.avatarUrl, 
          },
          toPlayer: {
            username: node.playerByToPlayerId.username,
            avatarUrl: node.playerByToPlayerId.avatarUrl,
          },
          points: node.points,
        }
      });
      setTransactions(transactions);
    }
  }, [playerTransactionsData]);

  const onChoosePlayer = (player) => {
    setChoosePlayerProfile({
      username: player.playerByPlayerId.username,
      avatarUrl: player.playerByPlayerId.avatarUrl,
      balance: 0,
    });
    setShowProfileModal(true);
  }

  const handleExitRoom = () => {
    Taro.navigateBack()
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
        onExitRoom={handleExitRoom}
        onViewSettlement={() => {}}
        onViewRanking={() => {}}
        onViewHistory={() => {}}
        onViewManual={() => {}}
      />
    )
  }

  return (
    <View className="min-h-screen bg-gray-50">
      {/* Header */}
      <View className="bg-white border-b p-4 flex items-center justify-between">
        <View className="flex items-center gap-2">
          <View className="text-lg font-semibold">打牌记账 2 房间</View>
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
              <TaroButton onClick={() => onChoosePlayer(player)} className="flex flex-col items-center gap-2 w-full">
                <PlayerAvatar name={player.playerByPlayerId.username} size="lg" />
                <View className="text-xs font-medium truncate w-full">{player.playerByPlayerId.username}</View>
                <View className="text-sm font-bold text-orange-500">¥0</View>
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
            onClick={() => setShowTransferModal(true)} 
            className="bg-green-500 px-8"
            hoverClass="hover-bg-green-600"
          >
            转账
          </TaroButton>
        </View>
        {/* Bottom Actions */}
        <View className="flex justify-center gap-4">
          <TaroButton 
            onClick={() => setCurrentView('settlement')} 
            className="bg-orange-500"
            hoverClass="hover-bg-orange-600"
          >
            结算
          </TaroButton>
          <TaroButton>客服</TaroButton>
          <TaroButton onClick={handleExitRoom}>退房</TaroButton>
        </View>
      </View>
      {/* Modals */}
      <PlayerProfileModal
        isOpen={showProfileModal}
        onClose={() => setShowProfileModal(false)}
        player={choosePlayerProfile}
        onUpdateNickname={() => {}}
        onExitRoom={handleExitRoom}
      />
      <SpendingLimitModal
        isOpen={showSpendingModal}
        onClose={() => setShowSpendingModal(false)}
        onConfirm={() => setShowSpendingModal(false)}
      />
      <TransferModal
        isOpen={showTransferModal}
        onClose={() => setShowTransferModal(false)}
        players={(roomPlayers || []).map(player => ({
          id: player.playerId,
          username: player.playerByPlayerId.username,
          avatarUrl: player.playerByPlayerId.avatarUrl
        }))}
        currentPlayer={
          {
            id: currentPlayer.playerId,
            username: currentPlayer.username,
            avatarUrl: currentPlayer.avatarUrl
          }
        }
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