import { View, Image } from '@tarojs/components'

export default function PlayerAvatar({ name, avatar, size = 'md' }) {
  const sizeClasses = {
    sm: 'h-8 w-8',
    md: 'h-12 w-12',
    lg: 'h-16 w-16',
  }
  return (
    <View className={sizeClasses[size]}>
      <Image
        src={avatar || '/assets/placeholder.svg'}
        alt={name}
        className='w-full h-full rounded-full'
        mode='aspectFill'
      />
    </View>
  )
} 