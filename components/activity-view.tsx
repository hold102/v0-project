'use client'

import { useApp } from '@/lib/app-context'
import { Card } from '@/components/ui/card'
import { categoryConfig, type ExpenseCategory } from '@/lib/types'
import { cn } from '@/lib/utils'

interface ActivityViewProps {
  onGroupSelect: (groupId: string) => void
}

export function ActivityView({ onGroupSelect }: ActivityViewProps) {
  const { groups, getUserById } = useApp()

  // Get all expenses sorted by date
  const allExpenses = groups
    .flatMap(group => 
      group.expenses.map(expense => ({
        ...expense,
        groupName: group.name,
        groupEmoji: group.emoji,
      }))
    )
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())

  // Group by date
  const groupedByDate = allExpenses.reduce((acc, expense) => {
    const date = expense.date
    if (!acc[date]) acc[date] = []
    acc[date].push(expense)
    return acc
  }, {} as Record<string, typeof allExpenses>)

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="px-5 pt-12 pb-6">
        <h1 className="text-2xl font-bold text-foreground mb-1">支出动态</h1>
        <p className="text-muted-foreground">查看所有支出记录</p>
      </div>

      {/* Activity Timeline */}
      <div className="px-5 space-y-6">
        {Object.entries(groupedByDate).map(([date, expenses]) => (
          <div key={date}>
            <h3 className="text-sm font-medium text-muted-foreground mb-3">
              {formatDateHeader(date)}
            </h3>
            <div className="space-y-3">
              {expenses.map((expense) => {
                const payer = getUserById(expense.paidBy)
                const config = categoryConfig[expense.category as ExpenseCategory]

                return (
                  <Card 
                    key={expense.id}
                    className="p-4 cursor-pointer hover:shadow-md transition-all"
                    onClick={() => onGroupSelect(expense.groupId)}
                  >
                    <div className="flex items-center gap-3">
                      <div className={cn('w-12 h-12 rounded-xl flex items-center justify-center text-xl', config.color)}>
                        {config.emoji}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold text-foreground truncate">{expense.description}</h4>
                        <p className="text-sm text-muted-foreground">
                          {payer?.name} 支付 · {expense.groupEmoji} {expense.groupName}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-foreground">RM {expense.amount.toFixed(2)}</p>
                        <p className="text-xs text-muted-foreground">
                          {expense.splitBetween.length}人分摊
                        </p>
                      </div>
                    </div>
                  </Card>
                )
              })}
            </div>
          </div>
        ))}

        {allExpenses.length === 0 && (
          <div className="text-center py-12">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
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
