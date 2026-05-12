'use client'

import { useState } from 'react'
import { useApp } from '@/lib/app-context'
import { ArrowLeft, Check, Sparkles } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { categoryConfig, type ExpenseCategory } from '@/lib/types'
import { cn } from '@/lib/utils'

interface AddExpenseViewProps {
  groupId?: string
  onBack: () => void
  onSuccess: (groupId: string) => void
}

export function AddExpenseView({ groupId, onBack, onSuccess }: AddExpenseViewProps) {
  const { groups, currentUser, addExpense, addGroup, users } = useApp()
  
  const [step, setStep] = useState<'select-group' | 'expense-details' | 'split'>( 
    groupId ? 'expense-details' : 'select-group'
  )
  const [selectedGroupId, setSelectedGroupId] = useState(groupId || '')
  const [description, setDescription] = useState('')
  const [amount, setAmount] = useState('')
  const [category, setCategory] = useState<ExpenseCategory>('food')
  const [paidBy, setPaidBy] = useState(currentUser.id)
  const [splitBetween, setSplitBetween] = useState<string[]>([])
  
  const [isCreatingGroup, setIsCreatingGroup] = useState(false)
  const [newGroupName, setNewGroupName] = useState('')
  const [newGroupEmoji, setNewGroupEmoji] = useState('🎉')
  const [selectedMembers, setSelectedMembers] = useState<string[]>([currentUser.id])

  const selectedGroup = groups.find(g => g.id === selectedGroupId)
  const emojis = ['🍕', '✈️', '🏠', '🎉', '💼', '🎮', '🛒', '☕', '🎬', '🏖️']

  const handleGroupSelect = (gId: string) => {
    setSelectedGroupId(gId)
    const group = groups.find(g => g.id === gId)
    if (group) {
      setSplitBetween(group.members.map(m => m.id))
      setStep('expense-details')
    }
  }

  const handleCreateGroup = () => {
    if (!newGroupName.trim() || selectedMembers.length < 2) return
    
    const members = users.filter(u => selectedMembers.includes(u.id))
    const newGroup = addGroup({
      name: newGroupName.trim(),
      emoji: newGroupEmoji,
      members,
    })
    setSelectedGroupId(newGroup.id)
    setSplitBetween(members.map(m => m.id))
    setIsCreatingGroup(false)
    setStep('expense-details')
  }

  const handleSubmit = () => {
    if (!description.trim() || !amount || !selectedGroupId || splitBetween.length === 0) return
    
    addExpense(selectedGroupId, {
      description: description.trim(),
      amount: parseFloat(amount),
      paidBy,
      splitBetween,
      category,
      date: new Date().toISOString().split('T')[0],
      groupId: selectedGroupId,
    })
    
    onSuccess(selectedGroupId)
  }

  const toggleMember = (memberId: string) => {
    setSplitBetween(prev => 
      prev.includes(memberId) 
        ? prev.filter(id => id !== memberId)
        : [...prev, memberId]
    )
  }

  const toggleNewGroupMember = (memberId: string) => {
    if (memberId === currentUser.id) return
    setSelectedMembers(prev =>
      prev.includes(memberId)
        ? prev.filter(id => id !== memberId)
        : [...prev, memberId]
    )
  }

  const perPersonAmount = amount && splitBetween.length > 0 
    ? (parseFloat(amount) / splitBetween.length).toFixed(2)
    : '0.00'

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-background/80 backdrop-blur-xl">
        <div className="px-6 pt-14 pb-4">
          <div className="flex items-center gap-4">
            <button
              onClick={step === 'select-group' ? onBack : () => setStep(step === 'split' ? 'expense-details' : 'select-group')}
              className="w-10 h-10 rounded-2xl bg-card border border-border flex items-center justify-center transition-all hover:bg-secondary active:scale-95"
            >
              <ArrowLeft className="w-5 h-5 text-foreground" />
            </button>
            <div className="flex-1">
              <h1 className="text-xl font-bold text-foreground">
                {step === 'select-group' ? '选择群组' : step === 'expense-details' ? '添加支出' : '分摊设置'}
              </h1>
              <p className="text-sm text-muted-foreground">
                {step === 'select-group' ? '步骤 1/3' : step === 'expense-details' ? '步骤 2/3' : '步骤 3/3'}
              </p>
            </div>
          </div>
          
          {/* Progress bar */}
          <div className="flex gap-2 mt-4">
            <div className={cn('h-1 flex-1 rounded-full', step !== 'select-group' || isCreatingGroup ? 'bg-primary' : 'bg-primary')} />
            <div className={cn('h-1 flex-1 rounded-full', step === 'expense-details' || step === 'split' ? 'bg-primary' : 'bg-muted')} />
            <div className={cn('h-1 flex-1 rounded-full', step === 'split' ? 'bg-primary' : 'bg-muted')} />
          </div>
        </div>
      </div>

      {/* Step 1: Select Group */}
      {step === 'select-group' && !isCreatingGroup && (
        <div className="px-6 py-4 space-y-4">
          <p className="text-muted-foreground text-sm">选择一个群组来添加支出</p>
          
          <button
            className="w-full rounded-2xl border-2 border-dashed border-primary/30 bg-primary/5 p-5 flex items-center gap-4 hover:border-primary/50 transition-all active:scale-[0.98]"
            onClick={() => setIsCreatingGroup(true)}
          >
            <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-primary" />
            </div>
            <div className="text-left">
              <p className="font-semibold text-foreground">创建新群组</p>
              <p className="text-sm text-muted-foreground">与朋友开始新的分账</p>
            </div>
          </button>

          {groups.length > 0 && (
            <div className="space-y-3">
              <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">已有群组</p>
              {groups.map((group, index) => (
                <div
                  key={group.id}
                  className={cn(
                    'animate-slide-up rounded-2xl bg-card border border-border p-4 cursor-pointer transition-all hover:border-primary/30 active:scale-[0.98]',
                    selectedGroupId === group.id && 'ring-2 ring-primary border-primary'
                  )}
                  style={{ animationDelay: `${index * 50}ms` }}
                  onClick={() => handleGroupSelect(group.id)}
                >
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-secondary to-muted flex items-center justify-center text-xl shadow-sm">
                      {group.emoji}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-foreground">{group.name}</h3>
                      <p className="text-sm text-muted-foreground">{group.members.length} 位成员</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Create New Group */}
      {step === 'select-group' && isCreatingGroup && (
        <div className="px-6 py-4 space-y-6">
          <div className="space-y-3">
            <Label className="text-sm font-semibold">选择图标</Label>
            <div className="flex flex-wrap gap-2">
              {emojis.map((emoji) => (
                <button
                  key={emoji}
                  onClick={() => setNewGroupEmoji(emoji)}
                  className={cn(
                    'w-12 h-12 rounded-2xl text-xl transition-all',
                    newGroupEmoji === emoji 
                      ? 'bg-primary text-primary-foreground scale-110 shadow-lg shadow-primary/25' 
                      : 'bg-card border border-border hover:bg-secondary'
                  )}
                >
                  {emoji}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="groupName" className="text-sm font-semibold">群组名称</Label>
            <Input
              id="groupName"
              placeholder="例如：周末聚餐"
              value={newGroupName}
              onChange={(e) => setNewGroupName(e.target.value)}
              className="h-12 rounded-xl bg-card border-border"
            />
          </div>

          <div className="space-y-3">
            <Label className="text-sm font-semibold">选择成员 ({selectedMembers.length})</Label>
            <div className="grid grid-cols-2 gap-3">
              {users.map((user) => (
                <div
                  key={user.id}
                  className={cn(
                    'rounded-2xl bg-card border border-border p-3 cursor-pointer transition-all',
                    selectedMembers.includes(user.id) 
                      ? 'ring-2 ring-primary border-primary bg-primary/5' 
                      : 'hover:bg-secondary',
                    user.id === currentUser.id && 'opacity-60 cursor-not-allowed'
                  )}
                  onClick={() => toggleNewGroupMember(user.id)}
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-secondary to-muted flex items-center justify-center text-lg shadow-sm">
                      {user.avatar}
                    </div>
                    <span className="font-medium text-foreground text-sm flex-1">{user.name}</span>
                    {selectedMembers.includes(user.id) && (
                      <div className="w-5 h-5 rounded-full bg-primary flex items-center justify-center">
                        <Check className="w-3 h-3 text-primary-foreground" />
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <Button variant="outline" className="flex-1 h-12 rounded-xl" onClick={() => setIsCreatingGroup(false)}>
              取消
            </Button>
            <Button 
              className="flex-1 h-12 rounded-xl shadow-sm" 
              onClick={handleCreateGroup}
              disabled={!newGroupName.trim() || selectedMembers.length < 2}
            >
              创建群组
            </Button>
          </div>
        </div>
      )}

      {/* Step 2: Expense Details */}
      {step === 'expense-details' && (
        <div className="px-6 py-4 space-y-6">
          {selectedGroup && (
            <div className="rounded-2xl bg-gradient-to-br from-secondary/50 to-muted/50 border border-border p-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-card border border-border flex items-center justify-center text-xl shadow-sm">
                  {selectedGroup.emoji}
                </div>
                <div>
                  <p className="font-semibold text-foreground">{selectedGroup.name}</p>
                  <p className="text-xs text-muted-foreground">{selectedGroup.members.length} 位成员</p>
                </div>
              </div>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="amount" className="text-sm font-semibold">金额 (RM)</Label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-2xl font-bold text-muted-foreground">RM</span>
              <Input
                id="amount"
                type="number"
                inputMode="decimal"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="h-16 pl-16 text-3xl font-bold text-center rounded-2xl bg-card border-border"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description" className="text-sm font-semibold">描述</Label>
            <Input
              id="description"
              placeholder="这笔钱是花在什么上的？"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="h-12 rounded-xl bg-card border-border"
            />
          </div>

          <div className="space-y-3">
            <Label className="text-sm font-semibold">类别</Label>
            <div className="grid grid-cols-4 gap-2">
              {(Object.entries(categoryConfig) as [ExpenseCategory, typeof categoryConfig[ExpenseCategory]][]).map(([key, config]) => (
                <button
                  key={key}
                  onClick={() => setCategory(key)}
                  className={cn(
                    'p-3 rounded-2xl text-center transition-all',
                    category === key 
                      ? 'bg-primary text-primary-foreground scale-105 shadow-lg shadow-primary/25' 
                      : 'bg-card border border-border hover:bg-secondary'
                  )}
                >
                  <div className="text-xl mb-1">{config.emoji}</div>
                  <div className="text-[10px] font-semibold">{config.label}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-3">
            <Label className="text-sm font-semibold">谁付的钱？</Label>
            <div className="flex flex-wrap gap-2">
              {selectedGroup?.members.map((member) => (
                <button
                  key={member.id}
                  onClick={() => setPaidBy(member.id)}
                  className={cn(
                    'px-4 py-2.5 rounded-full flex items-center gap-2 transition-all',
                    paidBy === member.id 
                      ? 'bg-primary text-primary-foreground shadow-lg shadow-primary/25' 
                      : 'bg-card border border-border hover:bg-secondary'
                  )}
                >
                  <span>{member.avatar}</span>
                  <span className="font-medium text-sm">{member.name}</span>
                </button>
              ))}
            </div>
          </div>

          <Button 
            className="w-full h-12 rounded-xl shadow-sm mt-4" 
            onClick={() => setStep('split')}
            disabled={!amount || !description.trim()}
          >
            下一步：设置分摊
          </Button>
        </div>
      )}

      {/* Step 3: Split Settings */}
      {step === 'split' && (
        <div className="px-6 py-4 space-y-6">
          <div className="rounded-2xl bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 p-5 text-center">
            <p className="text-muted-foreground text-sm font-medium mb-1">总金额</p>
            <p className="text-4xl font-bold text-foreground tracking-tight">RM {parseFloat(amount || '0').toFixed(2)}</p>
            <div className="flex items-center justify-center gap-2 mt-3">
              <span className="px-3 py-1 rounded-full bg-primary/10 text-primary text-sm font-semibold">
                {splitBetween.length} 人分摊
              </span>
              <span className="px-3 py-1 rounded-full bg-card border border-border text-foreground text-sm font-semibold">
                每人 RM {perPersonAmount}
              </span>
            </div>
          </div>

          <div className="space-y-3">
            <Label className="text-sm font-semibold">谁要参与分摊？</Label>
            <div className="space-y-2">
              {selectedGroup?.members.map((member, index) => (
                <div
                  key={member.id}
                  className={cn(
                    'animate-slide-up rounded-2xl bg-card border border-border p-4 cursor-pointer transition-all',
                    splitBetween.includes(member.id) 
                      ? 'ring-2 ring-primary border-primary bg-primary/5' 
                      : 'hover:bg-secondary'
                  )}
                  style={{ animationDelay: `${index * 50}ms` }}
                  onClick={() => toggleMember(member.id)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-secondary to-muted flex items-center justify-center text-lg shadow-sm">
                        {member.avatar}
                      </div>
                      <span className="font-semibold text-foreground">{member.name}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      {splitBetween.includes(member.id) && (
                        <span className="text-sm text-primary font-semibold">
                          RM {perPersonAmount}
                        </span>
                      )}
                      <div className={cn(
                        'w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all',
                        splitBetween.includes(member.id) 
                          ? 'bg-primary border-primary' 
                          : 'border-muted-foreground/30'
                      )}>
                        {splitBetween.includes(member.id) && (
                          <Check className="w-4 h-4 text-primary-foreground" />
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <Button variant="outline" className="flex-1 h-12 rounded-xl" onClick={() => setStep('expense-details')}>
              返回
            </Button>
            <Button 
              className="flex-1 h-12 rounded-xl shadow-sm" 
              onClick={handleSubmit}
              disabled={splitBetween.length === 0}
            >
              保存支出
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
