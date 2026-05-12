'use client'

import { useState } from 'react'
import { useApp } from '@/lib/app-context'
import { ArrowLeft, Check } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
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
  
  // For creating new group
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
    if (memberId === currentUser.id) return // Can't remove yourself
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
      <div className="sticky top-0 z-40 bg-background/80 backdrop-blur-xl border-b border-border">
        <div className="px-4 py-4 flex items-center gap-4">
          <button
            onClick={step === 'select-group' ? onBack : () => setStep('select-group')}
            className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>
          <h1 className="text-lg font-semibold text-foreground">
            {step === 'select-group' ? '选择群组' : step === 'expense-details' ? '添加支出' : '分摊设置'}
          </h1>
        </div>
      </div>

      {/* Step 1: Select Group */}
      {step === 'select-group' && !isCreatingGroup && (
        <div className="px-5 py-4 space-y-4">
          <p className="text-muted-foreground text-sm">选择一个群组来添加支出，或创建新群组</p>
          
          <Button
            variant="outline"
            className="w-full h-16 border-dashed border-2 justify-start gap-3"
            onClick={() => setIsCreatingGroup(true)}
          >
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
              <span className="text-xl">+</span>
            </div>
            <span className="font-medium">创建新群组</span>
          </Button>

          {groups.map((group) => (
            <Card
              key={group.id}
              className={cn(
                'p-4 cursor-pointer transition-all',
                selectedGroupId === group.id ? 'ring-2 ring-primary' : 'hover:bg-muted/50'
              )}
              onClick={() => handleGroupSelect(group.id)}
            >
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center text-xl">
                  {group.emoji}
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-foreground">{group.name}</h3>
                  <p className="text-sm text-muted-foreground">{group.members.length} 位成员</p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Create New Group */}
      {step === 'select-group' && isCreatingGroup && (
        <div className="px-5 py-4 space-y-6">
          <div className="space-y-3">
            <Label>群组图标</Label>
            <div className="flex flex-wrap gap-2">
              {emojis.map((emoji) => (
                <button
                  key={emoji}
                  onClick={() => setNewGroupEmoji(emoji)}
                  className={cn(
                    'w-12 h-12 rounded-xl text-xl transition-all',
                    newGroupEmoji === emoji 
                      ? 'bg-primary text-primary-foreground scale-110' 
                      : 'bg-secondary hover:bg-muted'
                  )}
                >
                  {emoji}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="groupName">群组名称</Label>
            <Input
              id="groupName"
              placeholder="例如：周末聚餐"
              value={newGroupName}
              onChange={(e) => setNewGroupName(e.target.value)}
              className="h-12"
            />
          </div>

          <div className="space-y-3">
            <Label>选择成员 ({selectedMembers.length})</Label>
            <div className="grid grid-cols-2 gap-3">
              {users.map((user) => (
                <Card
                  key={user.id}
                  className={cn(
                    'p-3 cursor-pointer transition-all',
                    selectedMembers.includes(user.id) 
                      ? 'ring-2 ring-primary bg-primary/5' 
                      : 'hover:bg-muted/50',
                    user.id === currentUser.id && 'opacity-60'
                  )}
                  onClick={() => toggleNewGroupMember(user.id)}
                >
                  <div className="flex items-center gap-2">
                    <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-lg">
                      {user.avatar}
                    </div>
                    <span className="font-medium text-foreground text-sm">{user.name}</span>
                    {selectedMembers.includes(user.id) && (
                      <Check className="w-4 h-4 text-primary ml-auto" />
                    )}
                  </div>
                </Card>
              ))}
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <Button variant="outline" className="flex-1" onClick={() => setIsCreatingGroup(false)}>
              取消
            </Button>
            <Button 
              className="flex-1" 
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
        <div className="px-5 py-4 space-y-6">
          {selectedGroup && (
            <Card className="p-3 bg-secondary/50">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-card flex items-center justify-center text-xl">
                  {selectedGroup.emoji}
                </div>
                <div>
                  <p className="font-medium text-foreground">{selectedGroup.name}</p>
                  <p className="text-xs text-muted-foreground">{selectedGroup.members.length} 位成员</p>
                </div>
              </div>
            </Card>
          )}

          <div className="space-y-2">
            <Label htmlFor="amount">金额 (RM)</Label>
            <Input
              id="amount"
              type="number"
              inputMode="decimal"
              placeholder="0.00"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="h-14 text-2xl font-bold text-center"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">描述</Label>
            <Input
              id="description"
              placeholder="这笔钱是花在什么上的？"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="h-12"
            />
          </div>

          <div className="space-y-3">
            <Label>类别</Label>
            <div className="grid grid-cols-4 gap-2">
              {(Object.entries(categoryConfig) as [ExpenseCategory, typeof categoryConfig[ExpenseCategory]][]).map(([key, config]) => (
                <button
                  key={key}
                  onClick={() => setCategory(key)}
                  className={cn(
                    'p-3 rounded-xl text-center transition-all',
                    category === key 
                      ? 'bg-primary text-primary-foreground scale-105' 
                      : 'bg-secondary hover:bg-muted'
                  )}
                >
                  <div className="text-xl mb-1">{config.emoji}</div>
                  <div className="text-xs font-medium">{config.label}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-3">
            <Label>谁付的钱？</Label>
            <div className="flex flex-wrap gap-2">
              {selectedGroup?.members.map((member) => (
                <button
                  key={member.id}
                  onClick={() => setPaidBy(member.id)}
                  className={cn(
                    'px-4 py-2 rounded-full flex items-center gap-2 transition-all',
                    paidBy === member.id 
                      ? 'bg-primary text-primary-foreground' 
                      : 'bg-secondary hover:bg-muted'
                  )}
                >
                  <span>{member.avatar}</span>
                  <span className="font-medium">{member.name}</span>
                </button>
              ))}
            </div>
          </div>

          <Button 
            className="w-full h-12" 
            onClick={() => setStep('split')}
            disabled={!amount || !description.trim()}
          >
            下一步：设置分摊
          </Button>
        </div>
      )}

      {/* Step 3: Split Settings */}
      {step === 'split' && (
        <div className="px-5 py-4 space-y-6">
          <Card className="p-4 bg-gradient-to-r from-primary/10 to-accent/10">
            <div className="text-center">
              <p className="text-muted-foreground text-sm">总金额</p>
              <p className="text-3xl font-bold text-foreground">RM {parseFloat(amount || '0').toFixed(2)}</p>
              <p className="text-sm text-muted-foreground mt-2">
                {splitBetween.length} 人分摊 · 每人 RM {perPersonAmount}
              </p>
            </div>
          </Card>

          <div className="space-y-3">
            <Label>谁要参与分摊？</Label>
            <div className="space-y-2">
              {selectedGroup?.members.map((member) => (
                <Card
                  key={member.id}
                  className={cn(
                    'p-4 cursor-pointer transition-all',
                    splitBetween.includes(member.id) 
                      ? 'ring-2 ring-primary bg-primary/5' 
                      : 'hover:bg-muted/50'
                  )}
                  onClick={() => toggleMember(member.id)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-lg">
                        {member.avatar}
                      </div>
                      <span className="font-medium text-foreground">{member.name}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      {splitBetween.includes(member.id) && (
                        <span className="text-sm text-muted-foreground">
                          RM {perPersonAmount}
                        </span>
                      )}
                      <div className={cn(
                        'w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all',
                        splitBetween.includes(member.id) 
                          ? 'bg-primary border-primary' 
                          : 'border-muted-foreground'
                      )}>
                        {splitBetween.includes(member.id) && (
                          <Check className="w-4 h-4 text-primary-foreground" />
                        )}
                      </div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <Button variant="outline" className="flex-1" onClick={() => setStep('expense-details')}>
              返回
            </Button>
            <Button 
              className="flex-1" 
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
