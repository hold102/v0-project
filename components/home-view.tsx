'use client'

import { useApp } from '@/lib/app-context'
import { ArrowDownLeft, ArrowUpRight, TrendingUp } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import type { Group } from '@/lib/types'

interface HomeViewProps {
  onGroupSelect: (groupId: string) => void
}

export function HomeView({ onGroupSelect }: HomeViewProps) {
  const { currentUser, groups, getTotalOwed, getTotalOwing, calculateBalances, getUserById } = useApp()
  
  const totalOwed = getTotalOwed()
  const totalOwing = getTotalOwing()
  const netBalance = totalOwed - totalOwing

  // Get recent activity
  const recentActivity = groups
    .flatMap(group => 
      group.expenses.map(expense => ({
        ...expense,
        groupName: group.name,
        groupEmoji: group.emoji,
      }))
    )
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 5)

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="px-5 pt-12 pb-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-muted-foreground text-sm">欢迎回来</p>
            <h1 className="text-2xl font-bold text-foreground">{currentUser.name} {currentUser.avatar}</h1>
          </div>
          <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
            <TrendingUp className="w-6 h-6 text-primary" />
          </div>
        </div>

        {/* Balance Card */}
        <Card className="p-5 bg-gradient-to-br from-primary to-primary/80 text-primary-foreground border-0 shadow-xl shadow-primary/20">
          <p className="text-primary-foreground/80 text-sm mb-1">净余额</p>
          <h2 className={cn(
            'text-4xl font-bold mb-4',
            netBalance >= 0 ? 'text-primary-foreground' : 'text-primary-foreground'
          )}>
            {netBalance >= 0 ? '+' : ''} RM {netBalance.toFixed(2)}
          </h2>
          <div className="flex gap-4">
            <div className="flex-1 bg-primary-foreground/10 rounded-xl p-3">
              <div className="flex items-center gap-2 mb-1">
                <ArrowDownLeft className="w-4 h-4 text-green-300" />
                <span className="text-xs text-primary-foreground/80">应收</span>
              </div>
              <p className="text-lg font-semibold">RM {totalOwed.toFixed(2)}</p>
            </div>
            <div className="flex-1 bg-primary-foreground/10 rounded-xl p-3">
              <div className="flex items-center gap-2 mb-1">
                <ArrowUpRight className="w-4 h-4 text-red-300" />
                <span className="text-xs text-primary-foreground/80">应付</span>
              </div>
              <p className="text-lg font-semibold">RM {totalOwing.toFixed(2)}</p>
            </div>
          </div>
        </Card>
      </div>

      {/* Groups Section */}
      <div className="px-5 mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-foreground">我的群组</h3>
          <span className="text-sm text-muted-foreground">{groups.length} 个群组</span>
        </div>
        <div className="flex gap-3 overflow-x-auto pb-2 -mx-5 px-5 scrollbar-hide">
          {groups.map((group) => (
            <GroupCard 
              key={group.id} 
              group={group} 
              onClick={() => onGroupSelect(group.id)}
              calculateBalances={calculateBalances}
              getUserById={getUserById}
              currentUserId={currentUser.id}
            />
          ))}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="px-5">
        <h3 className="text-lg font-semibold text-foreground mb-4">最近动态</h3>
        <div className="space-y-3">
          {recentActivity.map((expense) => {
            const payer = getUserById(expense.paidBy)
            return (
              <Card 
                key={expense.id} 
                className="p-4 flex items-center gap-4 cursor-pointer hover:bg-muted/50 transition-colors"
                onClick={() => onGroupSelect(expense.groupId)}
              >
                <div className="w-12 h-12 rounded-full bg-secondary flex items-center justify-center text-xl">
                  {expense.groupEmoji}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-foreground truncate">{expense.description}</p>
                  <p className="text-sm text-muted-foreground">
                    {payer?.name} 支付 · {expense.groupName}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-foreground">RM {expense.amount.toFixed(2)}</p>
                  <p className="text-xs text-muted-foreground">{formatDate(expense.date)}</p>
                </div>
              </Card>
            )
          })}
        </div>
      </div>
    </div>
  )
}

interface GroupCardProps {
  group: Group
  onClick: () => void
  calculateBalances: (group: Group) => { from: string; to: string; amount: number }[]
  getUserById: (id: string) => { id: string; name: string; avatar: string } | undefined
  currentUserId: string
}

function GroupCard({ group, onClick, calculateBalances, currentUserId }: GroupCardProps) {
  const balances = calculateBalances(group)
  const myBalance = balances.reduce((acc, b) => {
    if (b.to === currentUserId) return acc + b.amount
    if (b.from === currentUserId) return acc - b.amount
    return acc
  }, 0)

  const totalExpenses = group.expenses.reduce((sum, e) => sum + e.amount, 0)

  return (
    <Card 
      className="min-w-[160px] p-4 cursor-pointer hover:shadow-md transition-all border border-border"
      onClick={onClick}
    >
      <div className="text-3xl mb-2">{group.emoji}</div>
      <h4 className="font-semibold text-foreground truncate">{group.name}</h4>
      <p className="text-xs text-muted-foreground mb-2">{group.members.length} 位成员</p>
      <div className={cn(
        'text-sm font-medium',
        myBalance > 0 ? 'text-green-600' : myBalance < 0 ? 'text-red-500' : 'text-muted-foreground'
      )}>
        {myBalance > 0 ? `+RM ${myBalance.toFixed(2)}` : myBalance < 0 ? `-RM ${Math.abs(myBalance).toFixed(2)}` : '已结清'}
      </div>
      <p className="text-xs text-muted-foreground mt-1">共 RM {totalExpenses.toFixed(2)}</p>
    </Card>
  )
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return '今天'
  if (diffDays === 1) return '昨天'
  if (diffDays < 7) return `${diffDays}天前`
  return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' })
}
