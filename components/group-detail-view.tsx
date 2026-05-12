'use client'

import { useState } from 'react'
import { useApp } from '@/lib/app-context'
import { ArrowLeft, Plus, Trash2, Receipt, ArrowRightLeft, Send } from 'lucide-react'
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
    <div className="min-h-screen pb-28">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-background/80 backdrop-blur-xl">
        <div className="px-6 pt-14 pb-4">
          <div className="flex items-center gap-4 mb-6">
            <button
              onClick={onBack}
              className="w-10 h-10 rounded-2xl bg-card border border-border flex items-center justify-center transition-all hover:bg-secondary active:scale-95"
            >
              <ArrowLeft className="w-5 h-5 text-foreground" />
            </button>
            <div className="flex-1">
              <h1 className="text-xl font-bold text-foreground flex items-center gap-2">
                {group.emoji} {group.name}
              </h1>
              <p className="text-sm text-muted-foreground">{group.members.length} 位成员</p>
            </div>
            <Button onClick={onAddExpense} size="sm" className="gap-1.5 rounded-xl h-10 px-4 shadow-sm">
              <Plus className="w-4 h-4" />
              添加
            </Button>
          </div>
        </div>
      </div>

      {/* Summary Card */}
      <div className="px-6 pb-6">
        <div className="rounded-3xl bg-gradient-to-br from-card to-secondary/50 border border-border p-5 shadow-sm">
          <div className="flex justify-between items-start mb-5">
            <div>
              <p className="text-sm text-muted-foreground font-medium">总支出</p>
              <p className="text-3xl font-bold text-foreground tracking-tight">RM {totalExpenses.toFixed(2)}</p>
            </div>
            <div className="text-right">
              <p className="text-sm text-muted-foreground font-medium">你的余额</p>
              <p className={cn(
                'text-2xl font-bold tracking-tight',
                myBalance > 0 ? 'text-emerald-600' : myBalance < 0 ? 'text-rose-500' : 'text-foreground'
              )}>
                {myBalance > 0 ? '+' : ''}{myBalance !== 0 ? `RM ${Math.abs(myBalance).toFixed(2)}` : '已结清'}
              </p>
            </div>
          </div>
          {/* Members Avatars */}
          <div className="flex items-center">
            {group.members.slice(0, 6).map((member, i) => (
              <div
                key={member.id}
                className="w-9 h-9 rounded-xl bg-card border-2 border-background flex items-center justify-center text-sm shadow-sm"
                style={{ marginLeft: i > 0 ? -6 : 0, zIndex: 10 - i }}
              >
                {member.avatar}
              </div>
            ))}
            {group.members.length > 6 && (
              <span className="text-xs text-muted-foreground ml-3 font-medium">+{group.members.length - 6}</span>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-6">
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="w-full grid grid-cols-2 h-12 rounded-2xl bg-secondary p-1">
            <TabsTrigger value="expenses" className="gap-2 rounded-xl data-[state=active]:bg-card data-[state=active]:shadow-sm">
              <Receipt className="w-4 h-4" />
              支出记录
            </TabsTrigger>
            <TabsTrigger value="balances" className="gap-2 rounded-xl data-[state=active]:bg-card data-[state=active]:shadow-sm">
              <ArrowRightLeft className="w-4 h-4" />
              结算
            </TabsTrigger>
          </TabsList>

          <TabsContent value="expenses" className="mt-5 space-y-3">
            {group.expenses.length === 0 ? (
              <div className="rounded-2xl bg-card border border-border p-10 text-center">
                <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-muted flex items-center justify-center">
                  <Receipt className="w-7 h-7 text-muted-foreground" />
                </div>
                <h3 className="font-semibold text-foreground mb-1">还没有支出</h3>
                <p className="text-muted-foreground text-sm mb-5">点击添加按钮记录第一笔支出</p>
                <Button onClick={onAddExpense} className="gap-2 rounded-xl">
                  <Plus className="w-4 h-4" />
                  添加支出
                </Button>
              </div>
            ) : (
              group.expenses
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .map((expense, index) => {
                  const payer = getUserById(expense.paidBy)
                  const config = categoryConfig[expense.category as ExpenseCategory]
                  const perPerson = expense.amount / expense.splitBetween.length

                  return (
                    <div 
                      key={expense.id} 
                      className="animate-slide-up rounded-2xl bg-card border border-border p-4"
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div className="flex items-start gap-4">
                        <div className={cn(
                          'w-12 h-12 rounded-2xl flex items-center justify-center text-xl shadow-sm',
                          config.color
                        )}>
                          {config.emoji}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <div>
                              <h4 className="font-semibold text-foreground">{expense.description}</h4>
                              <p className="text-sm text-muted-foreground">
                                {payer?.name} 支付 · {expense.splitBetween.length}人分摊
                              </p>
                            </div>
                            <div className="text-right shrink-0">
                              <p className="font-bold text-foreground">RM {expense.amount.toFixed(2)}</p>
                              <p className="text-xs text-muted-foreground">每人 RM {perPerson.toFixed(2)}</p>
                            </div>
                          </div>
                          <div className="flex items-center justify-between mt-3 pt-3 border-t border-border">
                            <span className="text-xs text-muted-foreground">{formatDate(expense.date)}</span>
                            <button 
                              onClick={() => deleteExpense(groupId, expense.id)}
                              className="text-muted-foreground hover:text-destructive transition-colors p-1.5 rounded-lg hover:bg-destructive/10"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })
            )}
          </TabsContent>

          <TabsContent value="balances" className="mt-5 space-y-3">
            {balances.length === 0 ? (
              <div className="rounded-2xl bg-card border border-border p-10 text-center">
                <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-emerald-100 flex items-center justify-center">
                  <span className="text-3xl">✓</span>
                </div>
                <h3 className="font-semibold text-foreground mb-1">全部结清</h3>
                <p className="text-muted-foreground text-sm">这个群组没有未结算的费用</p>
              </div>
            ) : (
              <>
                <p className="text-sm text-muted-foreground mb-4">以下是最简化的结算方案：</p>
                {balances.map((balance, index) => {
                  const fromUser = getUserById(balance.from)
                  const toUser = getUserById(balance.to)
                  const isMe = balance.from === currentUser.id

                  return (
                    <div 
                      key={index} 
                      className={cn(
                        'animate-slide-up rounded-2xl p-4 border',
                        isMe 
                          ? 'bg-rose-50 border-rose-200' 
                          : 'bg-emerald-50 border-emerald-200'
                      )}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2">
                          <div className="w-10 h-10 rounded-xl bg-card border border-border flex items-center justify-center text-lg shadow-sm">
                            {fromUser?.avatar}
                          </div>
                          <Send className={cn(
                            'w-4 h-4',
                            isMe ? 'text-rose-500' : 'text-emerald-600'
                          )} />
                          <div className="w-10 h-10 rounded-xl bg-card border border-border flex items-center justify-center text-lg shadow-sm">
                            {toUser?.avatar}
                          </div>
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-foreground text-sm">
                            {fromUser?.name} → {toUser?.name}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {isMe ? '你需要支付' : `待支付`}
                          </p>
                        </div>
                        <div className={cn(
                          'text-lg font-bold',
                          isMe ? 'text-rose-600' : 'text-emerald-600'
                        )}>
                          RM {balance.amount.toFixed(2)}
                        </div>
                      </div>
                    </div>
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
