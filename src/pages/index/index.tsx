import { View, Button as TaroButton, Input, Button, Text, Image } from "@tarojs/components";
import PlayerAvatar from "../../components/player-avatar.js";
import GameStatsDisplay from "../../components/game-stats.js";
import QRCodeModal from "../../components/qr-code-modal.js";
import { useIndexPageViewModel } from "../../hooks/useIndexPageViewModel";
import { useState } from "react";
import Taro from "@tarojs/taro";

export default function Index() {
  const {
    userInfo,
    gameStats,
    showQRModal,
    isLoggingIn,
    handleGetUserProfile,
    handleCreateRoom,
    handleJoinRoom,
    handleCloseQRModal,
  } = useIndexPageViewModel();

  const [showJoinRoomDialog, setShowJoinRoomDialog] = useState(false);
  const [roomId, setRoomId] = useState("");
  // 数据加载状态
  if (isLoggingIn) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg">正在加载...</View>
      </View>
    );
  }

  return (
    <View className="min-h-screen bg-gray-50">
      Header
      <View className="bg-white border-b p-4 flex items-center justify-between">
        <View className="text-lg font-semibold">打牌记账</View>
      </View>
      
      {/* Profile Section */}
      <View className="bg-white p-6 text-center">
        <PlayerAvatar
          name={userInfo?.username || "用户"}
          avatar={userInfo?.avatarUrl}
          onClick={handleGetUserProfile}
          size="lg"
        />
        <View className="text-xl font-semibold mt-3 mb-2">
          {userInfo?.username}
        </View>
        <GameStatsDisplay stats={gameStats} />
        
        {/* Game Record */}
        <View className="flex items-center justify-center gap-4 text-sm mb-6">
          <View>
            赢<View className="text-orange-500 font-semibold">{gameStats.wins}</View>次
          </View>
          <View>/</View>
          <View>
            输<View className="text-orange-500 font-semibold">{gameStats.losses}</View>次
          </View>
          <View>/</View>
          <View>
            胜率<View className="text-orange-500 font-semibold">{gameStats.winRate}</View>
          </View>
          <TaroButton 
            onClick={() => Taro.navigateTo({ url: '/pages/game-history/game-history' })}
            className="text-orange-500 border-orange-500 px-3 py-1 rounded text-xs"
          >
            战绩 &gt;
          </TaroButton>
        </View>
      </View>
      
      {/* Action Buttons */}
      <View className="p-4">
        <View className="grid grid-cols-2 gap-4">
          <TaroButton
            onClick={handleCreateRoom}
            className="bg-orange-500 h-12"
            hoverClass="hover-bg-orange-600"
          >
            我要开房
          </TaroButton>
          <TaroButton
            onClick={() => setShowJoinRoomDialog(true)}
            className="h-12 border-orange-500 text-orange-500"
          >
            加入房间
          </TaroButton>
          <TaroButton
            onClick={() => handleJoinRoom("jyyj")}
            className="h-12 border-orange-500 text-orange-500"
          >
            扫码进房
          </TaroButton>
        </View>
        
        {/* Bottom Navigation */}
        <View className="flex justify-center gap-4 pt-4 mt-4">
          {/* <TaroButton>客服</TaroButton> */}
          <TaroButton>获取头像昵称</TaroButton>
          <TaroButton 
            onClick={() => Taro.navigateTo({ url: '/pages/settlement-demo/settlement-demo' })}
            className="text-orange-500 border-orange-500"
          >
            查看结算演示
          </TaroButton>
          {/* <TaroButton>使用手册</TaroButton> */}
        </View>
      </View>
      
      {/* QR Code Modal */}
      <QRCodeModal
        isOpen={showQRModal}
        onClose={handleCloseQRModal}
        roomId="jyyj"
      />
      {/* 加入房间对话框，输入房间号 */}
      {showJoinRoomDialog && (
      <View className='fixed left-0 top-0 w-full h-full z-50 flex items-center justify-center bg-black bg-opacity-60'>
      <View className='bg-white rounded-lg p-6 w-80'>
        <Text className='block text-center text-lg font-semibold mb-4'>加入房间</Text>
        <View className='text-center flex flex-col gap-4'>
          <Text className='text-sm text-muted-foreground'>输入房间号加入房间</Text>
          <Input type="text" placeholder="请输入房间号" className="border-2 border-orange-500 rounded-md p-2" value={roomId} 
          onInput={(e) => {
            setRoomId(e.detail.value)
          }} />
          <TaroButton 
          className='w-full bg-orange-500'
          hoverClass="hover-bg-orange-600"
          onClick={() => {
            if (roomId) {
              handleJoinRoom(roomId)
              setShowJoinRoomDialog(false)
            } else {
              Taro.showToast({
                title: '请输入房间号',
                icon: 'none'
              })
            }
          }}
        >
          加入房间
        </TaroButton>
        </View>
        <TaroButton className='mt-4 w-full' onClick={() => setShowJoinRoomDialog(false)}>关闭</TaroButton>
      </View>
    </View>
      )}
    </View>
  );
} 