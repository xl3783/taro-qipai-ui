"use client"

import { View, Button, Text } from '@tarojs/components'
import { useState } from 'react'
import PlayerAvatar from "./player-avatar"

export default function TransactionHistory({ transactions, players }) {
  const [isExpanded, setIsExpanded] = useState(false)

  const getPlayerName = (playerId) => {
    return players.find((p) => p.id === playerId)?.name || "未知用户"
  }

  const getPlayerAvatar = (playerId) => {
    const player = players.find((p) => p.id === playerId)
    return player ? <PlayerAvatar name={player.name} size="sm" /> : null
  }

  const formatTime = (date) => {
    return new Date(date).toLocaleTimeString('zh-CN', {
      hour: '2-digit', minute: '2-digit', second: '2-digit',
    })
  }

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('zh-CN', {
      month: '2-digit', day: '2-digit',
    })
  }

  const getTransactionTypeText = (type) => {
    switch (type) {
      case 'TRANSFER': return '转账'
      case 'EXPENSE': return '消费'
      case 'SETTLEMENT': return '结算'
      case 'transfer': return '转账' // 兼容旧格式
      case 'expense': return '消费' // 兼容旧格式
      case 'settlement': return '结算' // 兼容旧格式
      default: return '交易'
    }
  }

  const totalAmount = transactions.reduce((sum, t) => sum + t.amount, 0)

  return (
    <View className='w-full rounded-lg border bg-card text-card-foreground shadow-sm'>
      <View className='p-4 border-b flex items-center justify-between'>
        <Text className='text-lg font-semibold'>
          房间流水 <Text className='text-sm font-normal text-muted-foreground'>({transactions.length}笔)</Text>
        </Text>
        <View className='flex items-center space-x-2'>
          <Text className='text-sm text-muted-foreground'>总计: <Text className='font-semibold text-orange-600'>¥{totalAmount}</Text></Text>
          <Button className='h-8 w-8 p-0' onClick={() => setIsExpanded(!isExpanded)}>
            {isExpanded ? '收起' : '展开'}
          </Button>
        </View>
      </View>
      {isExpanded && (
        <View className='p-4'>
          {transactions.length === 0 ? (
            <View className='text-center py-8 text-muted-foreground'>
              <Text className='text-4xl mb-2'>📄</Text>
              <Text>暂无交易记录</Text>
            </View>
          ) : (
            <View className='h-64 w-full overflow-y-auto'>
              <View className='space-y-3'>
                {transactions.map((transaction) => (
                  <View key={transaction.id} className='flex items-center justify-between p-3 bg-gray-50 rounded-lg mb-2'>
                    <View className='flex items-center space-x-3 flex-1'>
                      <View className='inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800'>
                        {getTransactionTypeText(transaction.type)}
                      </View>
                      <View className='flex items-center space-x-2 flex-1'>
                        <Text className='text-sm font-medium'>
                          {transaction.fromPlayer ? transaction.fromPlayer.name : getPlayerName(transaction.fromPlayerId)}
                        </Text>
                        <Text className='mx-1'>→</Text>
                        <Text className='text-sm font-medium'>
                          {transaction.toPlayer ? transaction.toPlayer.name : getPlayerName(transaction.toPlayerId)}
                        </Text>
                      </View>
                    </View>
                    <View className='text-right flex-shrink-0'>
                      <Text className='text-lg font-bold text-orange-600'>¥{transaction.amount}</Text>
                      <Text className='text-xs text-muted-foreground'>
                        {formatDate(transaction.timestamp)} {formatTime(transaction.timestamp)}
                      </Text>
                      {transaction.description && (
                        <Text className='text-xs text-gray-500 mt-1'>{transaction.description}</Text>
                      )}
                    </View>
                  </View>
                ))}
              </View>
            </View>
          )}
          {transactions.length > 0 && (
            <View className='mt-4 pt-3 border-t'>
              <View className='flex justify-between items-center text-sm'>
                <Text className='text-muted-foreground'>今日交易统计</Text>
                <View className='space-x-4'>
                  <Text>交易笔数: <Text className='font-semibold'>{transactions.length}</Text></Text>
                  <Text>交易总额: <Text className='font-semibold text-orange-600'>¥{totalAmount}</Text></Text>
                </View>
              </View>
            </View>
          )}
        </View>
      )}
    </View>
  )
} 