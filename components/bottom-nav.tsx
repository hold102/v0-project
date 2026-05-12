'use client'

import { Home, Users, PlusCircle, Activity, User } from 'lucide-react'
import { cn } from '@/lib/utils'

interface BottomNavProps {
  activeTab: string
  onTabChange: (tab: string) => void
}

const navItems = [
  { id: 'home', label: '首页', icon: Home },
  { id: 'groups', label: '群组', icon: Users },
  { id: 'add', label: '添加', icon: PlusCircle },
  { id: 'activity', label: '动态', icon: Activity },
  { id: 'profile', label: '我的', icon: User },
]

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-card border-t border-border">
      <div className="max-w-md mx-auto flex items-center justify-around py-2 px-4 safe-area-bottom">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = activeTab === item.id
          const isAdd = item.id === 'add'

          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={cn(
                'flex flex-col items-center gap-1 py-2 px-3 rounded-xl transition-all duration-200',
                isAdd && 'relative -top-4',
                isActive && !isAdd && 'text-primary',
                !isActive && !isAdd && 'text-muted-foreground hover:text-foreground'
              )}
            >
              {isAdd ? (
                <div className="w-14 h-14 bg-primary rounded-full flex items-center justify-center shadow-lg shadow-primary/30">
                  <Icon className="w-7 h-7 text-primary-foreground" />
                </div>
              ) : (
                <>
                  <Icon className={cn('w-6 h-6', isActive && 'scale-110')} />
                  <span className="text-xs font-medium">{item.label}</span>
                </>
              )}
            </button>
          )
        })}
      </div>
    </nav>
  )
}
