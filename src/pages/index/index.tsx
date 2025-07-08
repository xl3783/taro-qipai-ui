import React from "react";
import { View, Button as TaroButton } from "@tarojs/components";
import PlayerAvatar from "../../components/player-avatar.js";
import GameStatsDisplay from "../../components/game-stats.js";
import QRCodeModal from "../../components/qr-code-modal.js";
import { useIndexPageViewModel } from "../../hooks/useIndexPageViewModel";

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
    handleQRCodeScanned,
  } = useIndexPageViewModel();

  // 数据加载状态
  if (isLoggingIn) {
    return (
      <View className="min-h-screen bg-gray-50 flex items-center justify-center">
        <View className="text-lg">正在加载...</View>
      </View>
    );
  }
  return (
    <View>
      <View>
        <View>123</View>
      </View>
    </View>
  )

//   return (
//     <View className="min-h-screen bg-gray-50">
//       Header
//       <View className="bg-white border-b p-4 flex items-center justify-between">
//         <View className="text-lg font-semibold">打牌记账</View>
//       </View>
      
//       {/* Profile Section */}
//       <View className="bg-white p-6 text-center">
//         <PlayerAvatar
//           name={userInfo?.username || "用户"}
//           avatar={userInfo?.avatarUrl}
//           onClick={handleGetUserProfile}
//           size="lg"
//         />
//         <View className="text-xl font-semibold mt-3 mb-2">
//           {userInfo?.username}
//         </View>
//         <GameStatsDisplay stats={gameStats} />
        
//         {/* Game Record */}
//         <View className="flex items-center justify-center gap-4 text-sm mb-6">
//           <View>
//             赢<View className="text-orange-500 font-semibold">{gameStats.wins}</View>次
//           </View>
//           <View>/</View>
//           <View>
//             输<View className="text-orange-500 font-semibold">{gameStats.losses}</View>次
//           </View>
//           <View>/</View>
//           <View>
//             胜率<View className="text-orange-500 font-semibold">{gameStats.winRate}%</View>
//           </View>
//           {/* <View className="text-muted-foreground">战绩 &gt;</View> */}
//         </View>
//       </View>
      
//       {/* Action Buttons */}
//       <View className="p-4">
//         <View className="grid grid-cols-2 gap-4">
//           <TaroButton
//             onClick={handleCreateRoom}
//             className="bg-orange-500 h-12"
//             hoverClass="hover-bg-orange-600"
//           >
//             我要开房
//           </TaroButton>
//           <TaroButton
//             onClick={handleJoinRoom}
//             className="h-12 border-orange-500 text-orange-500"
//           >
//             扫码进房
//           </TaroButton>
//         </View>
        
//         {/* Bottom Navigation */}
//         <View className="flex justify-center gap-4 pt-4 mt-4">
//           <TaroButton>客服</TaroButton>
//           <TaroButton>获取头像昵称</TaroButton>
//           <TaroButton>使用手册</TaroButton>
//         </View>
//       </View>
      
//       {/* QR Code Modal */}
//       <QRCodeModal
//         isOpen={showQRModal}
//         onClose={handleCloseQRModal}
//         roomId="jyyj"
//       />
//     </View>
//   );
} 