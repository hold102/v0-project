'use client'

import { useApp } from '@/lib/app-context'
import { Card } from '@/components/ui/card'
import { Settings, HelpCircle, LogOut, ChevronRight, Moon, Bell } from 'lucide-react'

export function ProfileView() {
  const { currentUser, groups, getTotalOwed, getTotalOwing } = useApp()
  
  const totalExpenses = groups.reduce(
    (sum, group) => sum + group.expenses.reduce((s, e) => s + e.amount, 0), 
    0
  )
  const totalGroups = groups.length
  const totalOwed = getTotalOwed()
  const totalOwing = getTotalOwing()

  const menuItems = [
    { icon: Bell, label: '通知设置', description: '管理推送通知' },
    { icon: Moon, label: '深色模式', description: '切换主题外观' },
    { icon: Settings, label: '账户设置', description: '管理你的账户' },
    { icon: HelpCircle, label: '帮助与支持', description: '常见问题解答' },
  ]

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="px-5 pt-12 pb-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center text-4xl">
            {currentUser.avatar}
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground">{currentUser.name}</h1>
            <p className="text-muted-foreground">{currentUser.email}</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          <Card className="p-4 text-center">
            <p className="text-2xl font-bold text-foreground">{totalGroups}</p>
            <p className="text-sm text-muted-foreground">群组</p>
          </Card>
          <Card className="p-4 text-center">
            <p className="text-2xl font-bold text-foreground">RM {totalExpenses.toFixed(0)}</p>
            <p className="text-sm text-muted-foreground">总支出</p>
          </Card>
          <Card className="p-4 text-center bg-green-50">
            <p className="text-2xl font-bold text-green-600">RM {totalOwed.toFixed(2)}</p>
            <p className="text-sm text-muted-foreground">应收</p>
          </Card>
          <Card className="p-4 text-center bg-red-50">
            <p className="text-2xl font-bold text-red-500">RM {totalOwing.toFixed(2)}</p>
            <p className="text-sm text-muted-foreground">应付</p>
          </Card>
        </div>
      </div>

      {/* Menu */}
      <div className="px-5 space-y-3">
        <h3 className="text-sm font-medium text-muted-foreground mb-3">设置</h3>
        {menuItems.map((item) => (
          <Card 
            key={item.label}
            className="p-4 cursor-pointer hover:bg-muted/50 transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center">
                <item.icon className="w-5 h-5 text-muted-foreground" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-foreground">{item.label}</p>
                <p className="text-sm text-muted-foreground">{item.description}</p>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </div>
          </Card>
        ))}

        <Card className="p-4 mt-6 cursor-pointer hover:bg-red-50 transition-colors">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
              <LogOut className="w-5 h-5 text-red-500" />
            </div>
            <p className="font-medium text-red-500">退出登录</p>
          </div>
        </Card>
      </div>

      {/* App Info */}
      <div className="px-5 py-8 text-center">
        <p className="text-sm text-muted-foreground">SplitEase v1.0.0</p>
        <p className="text-xs text-muted-foreground mt-1">© 2026 Shortcut Asia 实习挑战</p>
      </div>
    </div>
  )
}
