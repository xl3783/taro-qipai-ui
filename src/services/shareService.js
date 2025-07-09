import Taro from '@tarojs/taro'

export class ShareService {
  /**
   * 分享房间给好友
   */
  static async shareRoom(roomId, roomName) {
    try {
      await Taro.shareAppMessage({
        title: `邀请你加入房间: ${roomName}`,
        path: `/pages/room/room?roomId=${roomId}&roomName=${encodeURIComponent(roomName)}`,
        imageUrl: '/assets/placeholder-logo.png'
      })
      
      Taro.showToast({
        title: '分享成功',
        icon: 'success'
      })
    } catch (error) {
      console.error('分享失败:', error)
      Taro.showToast({
        title: '分享失败',
        icon: 'none'
      })
    }
  }

  /**
   * 分享结算结果
   */
  static async shareSettlement(roomId, roomName, participants) {
    try {
      const sortedParticipants = [...participants].sort((a, b) => (b.finalScore || 0) - (a.finalScore || 0))
      const winner = sortedParticipants[0]
      
      await Taro.shareAppMessage({
        title: `${roomName} 结算结果 - ${winner?.playerByPlayerId?.username || '玩家'} 获得第一名！`,
        path: `/pages/room/room?roomId=${roomId}&roomName=${encodeURIComponent(roomName)}`,
        imageUrl: '/assets/placeholder-logo.png'
      })
      
      Taro.showToast({
        title: '分享成功',
        icon: 'success'
      })
    } catch (error) {
      console.error('分享失败:', error)
      Taro.showToast({
        title: '分享失败',
        icon: 'none'
      })
    }
  }

  /**
   * 复制房间号到剪贴板
   */
  static async copyRoomId(roomId) {
    try {
      await Taro.setClipboardData({
        data: roomId
      })
      
      Taro.showToast({
        title: '房间号已复制',
        icon: 'success'
      })
    } catch (error) {
      console.error('复制失败:', error)
      Taro.showToast({
        title: '复制失败',
        icon: 'none'
      })
    }
  }

  /**
   * 保存图片到相册
   */
  static async saveImageToAlbum(filePath) {
    try {
      await Taro.saveImageToPhotosAlbum({
        filePath: filePath
      })
      
      Taro.showToast({
        title: '保存成功',
        icon: 'success'
      })
    } catch (error) {
      console.error('保存失败:', error)
      Taro.showToast({
        title: '保存失败',
        icon: 'none'
      })
    }
  }

  /**
   * 显示分享选项
   */
  static async showShareOptions(roomId, roomName, participants = null) {
    const options = ['分享给好友', '复制房间号']
    
    if (participants) {
      options.push('分享结算结果')
    }
    
    try {
      const res = await Taro.showActionSheet({
        itemList: options
      })
      
      switch (res.tapIndex) {
        case 0:
          await this.shareRoom(roomId, roomName)
          break
        case 1:
          await this.copyRoomId(roomId)
          break
        case 2:
          if (participants) {
            await this.shareSettlement(roomId, roomName, participants)
          }
          break
      }
    } catch (error) {
      console.error('显示分享选项失败:', error)
    }
  }

  /**
   * 生成分享数据
   */
  static generateShareData(roomId, roomName, participants = []) {
    const sortedParticipants = [...participants].sort((a, b) => (b.finalScore || 0) - (a.finalScore || 0))
    const totalScore = participants.reduce((sum, p) => sum + (p.finalScore || 0), 0)
    
    return {
      roomId,
      roomName,
      participants: sortedParticipants,
      totalScore,
      winner: sortedParticipants[0] || null,
      timestamp: new Date().toLocaleString(),
      stats: {
        totalPlayers: participants.length,
        averageScore: participants.length > 0 ? Math.round(totalScore / participants.length) : 0,
        maxScore: Math.max(...participants.map(p => p.finalScore || 0)),
        minScore: Math.min(...participants.map(p => p.finalScore || 0))
      }
    }
  }
} 