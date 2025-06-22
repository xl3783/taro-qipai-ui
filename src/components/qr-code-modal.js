import { View, Button, Text, Image } from '@tarojs/components'

export default function QRCodeModal({ isOpen, onClose, roomId }) {
  if (!isOpen) return null
  return (
    <View className='fixed left-0 top-0 w-full h-full z-50 flex items-center justify-center bg-black bg-opacity-60'>
      <View className='bg-white rounded-lg p-6 w-80'>
        <Text className='block text-center text-lg font-semibold mb-4'>微信扫码二维码加入</Text>
        <View className='text-center space-y-4'>
          <Text className='text-lg font-semibold'>房号: <Text className='text-orange-500'>{roomId}</Text></Text>
          <Text className='text-sm text-muted-foreground'>邀请好友扫描以下二维码加入房间</Text>
          <View className='flex justify-center'>
            <View className='w-48 h-48 bg-gray-100 rounded-lg flex items-center justify-center'>
              {/* 用占位图片代替二维码 */}
              <Image src='/assets/placeholder.svg' className='w-32 h-32' />
            </View>
          </View>
          <Text className='text-sm text-muted-foreground'>也可以通过"转发"让好友加入</Text>
          <Button className='w-full bg-orange-500 hover:bg-orange-600'>转发给好友</Button>
        </View>
        <Button className='mt-4 w-full' onClick={onClose}>关闭</Button>
      </View>
    </View>
  )
} 