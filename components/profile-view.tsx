'use client'

import { useApp } from '@/lib/app-context'
import { Settings, HelpCircle, LogOut, ChevronRight, Moon, Bell, Shield, CreditCard } from 'lucide-react'
import { cn } from '@/lib/utils'

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
    { icon: Bell, label: '通知设置', description: '管理推送通知', color: 'bg-blue-100 text-blue-600' },
    { icon: Moon, label: '深色模式', description: '切换主题外观', color: 'bg-indigo-100 text-indigo-600' },
    { icon: CreditCard, label: '支付方式', description: '管理你的支付方式', color: 'bg-emerald-100 text-emerald-600' },
    { icon: Shield, label: '隐私安全', description: '账户安全设置', color: 'bg-amber-100 text-amber-600' },
    { icon: Settings, label: '账户设置', description: '管理你的账户', color: 'bg-gray-100 text-gray-600' },
    { icon: HelpCircle, label: '帮助与支持', description: '常见问题解答', color: 'bg-purple-100 text-purple-600' },
  ]

  return (
    <div className="min-h-screen pb-28">
      {/* Header */}
      <div className="px-6 pt-14 pb-6">
        <div className="flex items-center gap-4 mb-8">
          <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center text-4xl shadow-sm border border-border">
            {currentUser.avatar}
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground tracking-tight">{currentUser.name}</h1>
            <p className="text-muted-foreground text-sm">{currentUser.email}</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-2xl bg-card border border-border p-4">
            <p className="text-3xl font-bold text-foreground tracking-tight">{totalGroups}</p>
            <p className="text-xs text-muted-foreground font-medium mt-1">活跃群组</p>
          </div>
          <div className="rounded-2xl bg-card border border-border p-4">
            <p className="text-3xl font-bold text-foreground tracking-tight">RM {totalExpenses.toFixed(0)}</p>
            <p className="text-xs text-muted-foreground font-medium mt-1">总支出</p>
          </div>
          <div className="rounded-2xl bg-emerald-50 border border-emerald-200 p-4">
            <p className="text-3xl font-bold text-emerald-600 tracking-tight">RM {totalOwed.toFixed(2)}</p>
            <p className="text-xs text-emerald-700/70 font-medium mt-1">应收款项</p>
          </div>
          <div className="rounded-2xl bg-rose-50 border border-rose-200 p-4">
            <p className="text-3xl font-bold text-rose-500 tracking-tight">RM {totalOwing.toFixed(2)}</p>
            <p className="text-xs text-rose-700/70 font-medium mt-1">应付款项</p>
          </div>
        </div>
      </div>

      {/* Menu */}
      <div className="px-6 space-y-3">
        <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">设置</h3>
        {menuItems.map((item, index) => (
          <div 
            key={item.label}
            className="animate-slide-up rounded-2xl bg-card border border-border p-4 cursor-pointer hover:border-primary/30 hover:shadow-lg transition-all active:scale-[0.98]"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <div className="flex items-center gap-4">
              <div className={cn(
                'w-10 h-10 rounded-xl flex items-center justify-center',
                item.color
              )}>
                <item.icon className="w-5 h-5" />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-foreground">{item.label}</p>
                <p className="text-sm text-muted-foreground">{item.description}</p>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </div>
          </div>
        ))}

        <div className="pt-4">
          <div className="rounded-2xl bg-card border border-rose-200 p-4 cursor-pointer hover:bg-rose-50 transition-all active:scale-[0.98]">
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 rounded-xl bg-rose-100 flex items-center justify-center">
                <LogOut className="w-5 h-5 text-rose-500" />
              </div>
              <p className="font-semibold text-rose-500">退出登录</p>
            </div>
          </div>
        </div>
      </div>

      {/* App Info */}
      <div className="px-6 py-10 text-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-card border border-border mb-2">
          <span className="text-lg">💸</span>
          <span className="text-sm font-semibold text-foreground">SplitEase</span>
        </div>
        <p className="text-xs text-muted-foreground">v1.0.0 · Shortcut Asia 实习挑战</p>
      </div>
    </div>
  )
}
