'use client'

import { useState } from 'react'
import { useApp } from '@/lib/app-context'
import { ArrowLeft, Plus, Trash2, ChevronRight, Receipt, ArrowRightLeft } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { categoryConfig, type ExpenseCategory } from '@/lib/types'
import { cn } from '@/lib/utils'

interface GroupDetailViewProps {
  groupId: string
  onBack: () => void
  onAddExpense: () => void
}

export function GroupDetailView({ groupId, onBack, onAddExpense }: GroupDetailViewProps) {
  const { getGroupById, getUserById, calculateBalances, deleteExpense, currentUser } = useApp()
  const [activeTab, setActiveTab] = useState('expenses')
  
  const group = getGroupById(groupId)
  
  if (!group) {
    return (
      <div className="flex items-center justify-center h-screen">
        <p className="text-muted-foreground">群组未找到</p>
      </div>
    )
  }

  const balances = calculateBalances(group)
  const totalExpenses = group.expenses.reduce((sum, e) => sum + e.amount, 0)

  const myBalance = balances.reduce((acc, b) => {
    if (b.to === currentUser.id) return acc + b.amount
    if (b.from === currentUser.id) return acc - b.amount
    return acc
  }, 0)

  return (
    <div className="pb-24 min-h-screen">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-background/80 backdrop-blur-xl border-b border-border">
        <div className="px-4 py-4 flex items-center gap-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <div className="flex-1">
            <h1 className="text-lg font-semibold text-foreground flex items-center gap-2">
              {group.emoji} {group.name}
            </h1>
            <p className="text-sm text-muted-foreground">{group.members.length} 位成员</p>
          </div>
          <Button onClick={onAddExpense} size="sm" className="gap-1">
            <Plus className="w-4 h-4" />
            添加
          </Button>
        </div>
      </div>

      {/* Summary Card */}
      <div className="px-5 py-4">
        <Card className="p-4 bg-gradient-to-r from-secondary to-muted">
          <div className="flex justify-between items-start mb-3">
            <div>
              <p className="text-sm text-muted-foreground">总支出</p>
              <p className="text-2xl font-bold text-foreground">RM {totalExpenses.toFixed(2)}</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-muted-foreground">你的余额</p>
              <p className={cn(
                'text-xl font-bold',
                myBalance > 0 ? 'text-green-600' : myBalance < 0 ? 'text-red-500' : 'text-foreground'
              )}>
                {myBalance > 0 ? '+' : ''}{myBalance !== 0 ? `RM ${myBalance.toFixed(2)}` : '已结清'}
              </p>
            </div>
          </div>
          {/* Members Avatars */}
          <div className="flex items-center gap-1">
            {group.members.slice(0, 5).map((member, i) => (
              <div
                key={member.id}
                className="w-8 h-8 rounded-full bg-card border-2 border-background flex items-center justify-center text-sm"
                style={{ marginLeft: i > 0 ? -8 : 0, zIndex: 5 - i }}
              >
                {member.avatar}
              </div>
            ))}
            {group.members.length > 5 && (
              <span className="text-xs text-muted-foreground ml-2">+{group.members.length - 5}</span>
            )}
          </div>
        </Card>
      </div>

      {/* Tabs */}
      <div className="px-5">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="w-full grid grid-cols-2">
            <TabsTrigger value="expenses" className="gap-2">
              <Receipt className="w-4 h-4" />
              支出记录
            </TabsTrigger>
            <TabsTrigger value="balances" className="gap-2">
              <ArrowRightLeft className="w-4 h-4" />
              结算
            </TabsTrigger>
          </TabsList>

          <TabsContent value="expenses" className="mt-4 space-y-3">
            {group.expenses.length === 0 ? (
              <div className="text-center py-12">
                <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
                  <Receipt className="w-8 h-8 text-muted-foreground" />
                </div>
                <h3 className="font-semibold text-foreground mb-1">还没有支出</h3>
                <p className="text-muted-foreground text-sm mb-4">点击添加按钮记录第一笔支出</p>
                <Button onClick={onAddExpense} className="gap-2">
                  <Plus className="w-4 h-4" />
                  添加支出
                </Button>
              </div>
            ) : (
              group.expenses
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .map((expense) => {
                  const payer = getUserById(expense.paidBy)
                  const config = categoryConfig[expense.category as ExpenseCategory]
                  const perPerson = expense.amount / expense.splitBetween.length

                  return (
                    <Card key={expense.id} className="p-4">
                      <div className="flex items-start gap-3">
                        <div className={cn('w-12 h-12 rounded-xl flex items-center justify-center text-xl', config.color)}>
                          {config.emoji}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div>
                              <h4 className="font-semibold text-foreground">{expense.description}</h4>
                              <p className="text-sm text-muted-foreground">
                                {payer?.name} 支付 · {expense.splitBetween.length}人分摊
                              </p>
                            </div>
                            <div className="text-right">
                              <p className="font-bold text-foreground">RM {expense.amount.toFixed(2)}</p>
                              <p className="text-xs text-muted-foreground">每人 RM {perPerson.toFixed(2)}</p>
                            </div>
                          </div>
                          <div className="flex items-center justify-between mt-2">
                            <span className="text-xs text-muted-foreground">{formatDate(expense.date)}</span>
                            <button 
                              onClick={() => deleteExpense(groupId, expense.id)}
                              className="text-muted-foreground hover:text-destructive transition-colors p-1"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </Card>
                  )
                })
            )}
          </TabsContent>

          <TabsContent value="balances" className="mt-4 space-y-3">
            {balances.length === 0 ? (
              <div className="text-center py-12">
                <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-green-100 flex items-center justify-center">
                  <span className="text-3xl">✓</span>
                </div>
                <h3 className="font-semibold text-foreground mb-1">全部结清</h3>
                <p className="text-muted-foreground text-sm">这个群组没有未结算的费用</p>
              </div>
            ) : (
              <>
                <p className="text-sm text-muted-foreground mb-2">以下是最简化的结算方案：</p>
                {balances.map((balance, index) => {
                  const fromUser = getUserById(balance.from)
                  const toUser = getUserById(balance.to)
                  const isMe = balance.from === currentUser.id

                  return (
                    <Card 
                      key={index} 
                      className={cn(
                        'p-4 border-l-4',
                        isMe ? 'border-l-red-500 bg-red-50/50' : 'border-l-green-500 bg-green-50/50'
                      )}
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-lg">
                          {fromUser?.avatar}
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-foreground">{fromUser?.name}</span>
                            <ChevronRight className="w-4 h-4 text-muted-foreground" />
                            <span className="font-medium text-foreground">{toUser?.name}</span>
                          </div>
                          <p className="text-sm text-muted-foreground">
                            {isMe ? '你需要支付' : `${fromUser?.name}需要支付给${toUser?.name}`}
                          </p>
                        </div>
                        <div className={cn(
                          'text-lg font-bold',
                          isMe ? 'text-red-600' : 'text-green-600'
                        )}>
                          RM {balance.amount.toFixed(2)}
                        </div>
                      </div>
                    </Card>
                  )
                })}
              </>
            )}
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric', year: 'numeric' })
}
