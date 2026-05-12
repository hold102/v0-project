'use client'

import { useState } from 'react'
import { AppProvider } from '@/lib/app-context'
import { BottomNav } from '@/components/bottom-nav'
import { HomeView } from '@/components/home-view'
import { GroupsView } from '@/components/groups-view'
import { GroupDetailView } from '@/components/group-detail-view'
import { AddExpenseView } from '@/components/add-expense-view'
import { ActivityView } from '@/components/activity-view'
import { ProfileView } from '@/components/profile-view'

type View = 
  | { type: 'home' }
  | { type: 'groups' }
  | { type: 'group-detail'; groupId: string }
  | { type: 'add-expense'; groupId?: string }
  | { type: 'activity' }
  | { type: 'profile' }

function ExpenseSplitterApp() {
  const [view, setView] = useState<View>({ type: 'home' })
  const [activeTab, setActiveTab] = useState('home')

  const handleTabChange = (tab: string) => {
    setActiveTab(tab)
    switch (tab) {
      case 'home':
        setView({ type: 'home' })
        break
      case 'groups':
        setView({ type: 'groups' })
        break
      case 'add':
        setView({ type: 'add-expense' })
        break
      case 'activity':
        setView({ type: 'activity' })
        break
      case 'profile':
        setView({ type: 'profile' })
        break
    }
  }

  const handleGroupSelect = (groupId: string) => {
    setView({ type: 'group-detail', groupId })
  }

  const handleAddExpense = (groupId?: string) => {
    setView({ type: 'add-expense', groupId })
  }

  const handleBack = () => {
    setView({ type: activeTab as 'home' | 'groups' | 'activity' | 'profile' })
  }

  const handleExpenseSuccess = (groupId: string) => {
    setView({ type: 'group-detail', groupId })
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Phone Frame */}
      <div className="max-w-md mx-auto min-h-screen relative shadow-2xl bg-background">
        {view.type === 'home' && (
          <HomeView onGroupSelect={handleGroupSelect} />
        )}
        
        {view.type === 'groups' && (
          <GroupsView onGroupSelect={handleGroupSelect} />
        )}
        
        {view.type === 'group-detail' && (
          <GroupDetailView 
            groupId={view.groupId} 
            onBack={handleBack}
            onAddExpense={() => handleAddExpense(view.groupId)}
          />
        )}
        
        {view.type === 'add-expense' && (
          <AddExpenseView 
            groupId={view.groupId}
            onBack={handleBack}
            onSuccess={handleExpenseSuccess}
          />
        )}
        
        {view.type === 'activity' && (
          <ActivityView onGroupSelect={handleGroupSelect} />
        )}
        
        {view.type === 'profile' && (
          <ProfileView />
        )}

        {/* Bottom Navigation - only show when not in detail/add views */}
        {!['group-detail', 'add-expense'].includes(view.type) && (
          <BottomNav activeTab={activeTab} onTabChange={handleTabChange} />
        )}
      </div>
    </div>
  )
}

export default function ExpenseSplitterWrapper() {
  return (
    <AppProvider>
      <ExpenseSplitterApp />
    </AppProvider>
  )
}
