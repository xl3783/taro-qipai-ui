import { View, Text, Button as TaroButton, ScrollView } from "@tarojs/components";
import { useGameHistoryViewModel } from "../../hooks/useGameHistoryViewModel";
import "./game-history.scss";

export default function GameHistory() {
  const {
    rooms,
    stats,
    loading,
    error,
    refreshing,
    handleRoomClick,
    handleRefresh,
    clearError,
    formatTime,
    getStatusText,
    getStatusClass,
  } = useGameHistoryViewModel();

  // 加载状态
  if (loading) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg">正在加载...</View>
      </View>
    );
  }

  // 错误状态
  if (error) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-center">
          <View className="text-lg text-red-500 mb-4">加载失败: {error}</View>
          <TaroButton onClick={clearError} className="bg-orange-500 text-white px-6 py-2 rounded">
            重试
          </TaroButton>
        </View>
      </View>
    );
  }

  return (
    <View className="min-h-screen bg-gray-50 game-history">
      {/* Header */}
      <View className="bg-white border-b p-4">
        <View className="text-lg font-semibold text-center">战绩记录</View>
      </View>

      {/* Stats Section */}
      <View className="bg-white p-4 mb-4">
        <View className="grid grid-cols-2 gap-4">
          <View className="text-center p-3 bg-orange-50 rounded-lg">
            <View className="text-2xl font-bold text-orange-600">{stats.totalRooms}</View>
            <View className="text-sm text-gray-600">总房间数</View>
          </View>
          <View className="text-center p-3 bg-green-50 rounded-lg">
            <View className="text-2xl font-bold text-green-600">{stats.activeRooms}</View>
            <View className="text-sm text-gray-600">进行中</View>
          </View>
          <View className="text-center p-3 bg-blue-50 rounded-lg">
            <View className="text-2xl font-bold text-blue-600">{stats.settledRooms}</View>
            <View className="text-sm text-gray-600">已结束</View>
          </View>
          <View className="text-center p-3 bg-purple-50 rounded-lg">
            <View className="text-2xl font-bold text-purple-600">¥{stats.totalAmount}</View>
            <View className="text-sm text-gray-600">总金额</View>
          </View>
        </View>
      </View>

      {/* Room List */}
      <ScrollView 
        className="flex-1 px-4"
        scrollY
        refresherEnabled
        refresherTriggered={refreshing}
        onRefresherRefresh={handleRefresh}
      >
        {rooms.length === 0 ? (
          <View className="empty-state">
            <View className="empty-icon">
              <Text className="text-4xl">📊</Text>
            </View>
            <Text className="text-lg font-semibold text-gray-600 mb-2">暂无战绩记录</Text>
            <Text className="text-sm text-gray-500 text-center">
              开始创建房间或加入房间来记录你的战绩吧！
            </Text>
          </View>
        ) : (
          <View className="space-y-3 pb-4">
            {rooms.map((room) => (
              <View
                key={room.id}
                className="room-item bg-white rounded-lg p-4 shadow-sm border"
                onClick={() => handleRoomClick(room)}
              >
                <View className="flex items-center justify-between mb-2">
                  <Text className="font-semibold text-lg truncate flex-1 mr-2">
                    {room.name}
                  </Text>
                  <View className={`status-badge ${getStatusClass(room.status)} px-2 py-1 rounded-full text-xs`}>
                    {getStatusText(room.status)}
                  </View>
                </View>
                
                <View className="flex items-center justify-between text-sm text-gray-600 mb-2">
                  <Text>房主: {room.hostName}</Text>
                  <Text>{room.playerCount}人</Text>
                </View>
                
                <View className="flex items-center justify-between">
                  <Text className="text-sm text-gray-500">
                    {formatTime(room.createdAt)}
                  </Text>
                  <Text className="font-semibold text-orange-600">
                    ¥{room.totalAmount}
                  </Text>
                </View>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
} 