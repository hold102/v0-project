'use client'

import { useApp } from '@/lib/app-context'
import { categoryConfig, type ExpenseCategory } from '@/lib/types'
import { cn } from '@/lib/utils'
import { Clock, TrendingUp } from 'lucide-react'

interface ActivityViewProps {
  onGroupSelect: (groupId: string) => void
}

export function ActivityView({ onGroupSelect }: ActivityViewProps) {
  const { groups, getUserById } = useApp()

  const allExpenses = groups
    .flatMap(group => 
      group.expenses.map(expense => ({
        ...expense,
        groupName: group.name,
        groupEmoji: group.emoji,
      }))
    )
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())

  const groupedByDate = allExpenses.reduce((acc, expense) => {
    const date = expense.date
    if (!acc[date]) acc[date] = []
    acc[date].push(expense)
    return acc
  }, {} as Record<string, typeof allExpenses>)

  return (
    <div className="min-h-screen pb-28">
      {/* Header */}
      <div className="px-6 pt-14 pb-6">
        <h1 className="text-2xl font-bold text-foreground tracking-tight mb-1">动态</h1>
        <p className="text-muted-foreground text-sm">查看所有支出记录</p>
      </div>

      {/* Quick Stats */}
      <div className="px-6 mb-6">
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-2xl bg-card border border-border p-4">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center mb-3">
              <Clock className="w-5 h-5 text-primary" />
            </div>
            <p className="text-2xl font-bold text-foreground">{allExpenses.length}</p>
            <p className="text-xs text-muted-foreground">总记录</p>
          </div>
          <div className="rounded-2xl bg-card border border-border p-4">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center mb-3">
              <TrendingUp className="w-5 h-5 text-primary" />
            </div>
            <p className="text-2xl font-bold text-foreground">
              RM {allExpenses.reduce((sum, e) => sum + e.amount, 0).toFixed(0)}
            </p>
            <p className="text-xs text-muted-foreground">总金额</p>
          </div>
        </div>
      </div>

      {/* Activity Timeline */}
      <div className="px-6 space-y-6">
        {Object.entries(groupedByDate).map(([date, expenses]) => (
          <div key={date}>
            <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              {formatDateHeader(date)}
            </h3>
            <div className="space-y-3">
              {expenses.map((expense, index) => {
                const payer = getUserById(expense.paidBy)
                const config = categoryConfig[expense.category as ExpenseCategory]

                return (
                  <div 
                    key={expense.id}
                    className="animate-slide-up rounded-2xl bg-card border border-border p-4 cursor-pointer hover:border-primary/30 hover:shadow-lg transition-all active:scale-[0.98]"
                    style={{ animationDelay: `${index * 50}ms` }}
                    onClick={() => onGroupSelect(expense.groupId)}
                  >
                    <div className="flex items-center gap-4">
                      <div className={cn(
                        'w-12 h-12 rounded-2xl flex items-center justify-center text-xl shadow-sm',
                        config.color
                      )}>
                        {config.emoji}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold text-foreground truncate">{expense.description}</h4>
                        <p className="text-sm text-muted-foreground">
                          {payer?.name} 支付 · {expense.groupEmoji} {expense.groupName}
                        </p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className="font-bold text-foreground">RM {expense.amount.toFixed(2)}</p>
                        <p className="text-xs text-muted-foreground">
                          {expense.splitBetween.length}人分摊
                        </p>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        ))}

        {allExpenses.length === 0 && (
          <div className="rounded-2xl bg-card border border-border p-12 text-center">
            <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-muted flex items-center justify-center">
              <span className="text-3xl">📝</span>
            </div>
            <h3 className="font-semibold text-foreground mb-1">还没有支出记录</h3>
            <p className="text-muted-foreground text-sm">开始添加支出来跟踪分账</p>
          </div>
        )}
      </div>
    </div>
  )
}

function formatDateHeader(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return '今天'
  if (diffDays === 1) return '昨天'
  if (diffDays < 7) return `${diffDays}天前`
  
  return date.toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' })
}
