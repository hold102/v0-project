'use client'

import { useApp } from '@/lib/app-context'
import { Card } from '@/components/ui/card'
import { ChevronRight, Users } from 'lucide-react'
import { cn } from '@/lib/utils'

interface GroupsViewProps {
  onGroupSelect: (groupId: string) => void
}

export function GroupsView({ onGroupSelect }: GroupsViewProps) {
  const { groups, calculateBalances, currentUser } = useApp()

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="px-5 pt-12 pb-6">
        <h1 className="text-2xl font-bold text-foreground mb-1">我的群组</h1>
        <p className="text-muted-foreground">管理你的分账群组</p>
      </div>

      {/* Groups List */}
      <div className="px-5 space-y-4">
        {groups.map((group) => {
          const balances = calculateBalances(group)
          const myBalance = balances.reduce((acc, b) => {
            if (b.to === currentUser.id) return acc + b.amount
            if (b.from === currentUser.id) return acc - b.amount
            return acc
          }, 0)
          const totalExpenses = group.expenses.reduce((sum, e) => sum + e.amount, 0)

          return (
            <Card 
              key={group.id}
              className="p-4 cursor-pointer hover:shadow-md transition-all"
              onClick={() => onGroupSelect(group.id)}
            >
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 rounded-2xl bg-secondary flex items-center justify-center text-2xl">
                  {group.emoji}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-foreground">{group.name}</h3>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Users className="w-4 h-4" />
                    <span>{group.members.length} 位成员</span>
                    <span>·</span>
                    <span>{group.expenses.length} 笔支出</span>
                  </div>
                </div>
                <div className="text-right mr-2">
                  <p className={cn(
                    'font-semibold',
                    myBalance > 0 ? 'text-green-600' : myBalance < 0 ? 'text-red-500' : 'text-muted-foreground'
                  )}>
                    {myBalance > 0 ? `+RM ${myBalance.toFixed(2)}` : myBalance < 0 ? `-RM ${Math.abs(myBalance).toFixed(2)}` : '已结清'}
                  </p>
                  <p className="text-xs text-muted-foreground">共 RM {totalExpenses.toFixed(2)}</p>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </div>
            </Card>
          )
        })}

        {groups.length === 0 && (
          <div className="text-center py-12">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-muted flex items-center justify-center">
              <Users className="w-8 h-8 text-muted-foreground" />
            </div>
            <h3 className="font-semibold text-foreground mb-1">还没有群组</h3>
            <p className="text-muted-foreground text-sm">点击下方 + 按钮创建一个新群组</p>
          </div>
        )}
      </div>
    </div>
  )
}
