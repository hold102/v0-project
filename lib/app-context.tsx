'use client'

import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'
import type { Group, Expense, User, Balance } from '@/lib/types'

// Mock Users
const mockUsers: User[] = [
  { id: 'u1', name: '我', avatar: '👤', email: 'me@example.com' },
  { id: 'u2', name: '小明', avatar: '😎', email: 'ming@example.com' },
  { id: 'u3', name: '小红', avatar: '😊', email: 'hong@example.com' },
  { id: 'u4', name: '小李', avatar: '🤓', email: 'li@example.com' },
  { id: 'u5', name: '小王', avatar: '😄', email: 'wang@example.com' },
]

// Mock Groups with expenses
const mockGroups: Group[] = [
  {
    id: 'g1',
    name: '周末聚餐',
    emoji: '🍕',
    members: [mockUsers[0], mockUsers[1], mockUsers[2]],
    createdAt: '2026-05-01',
    expenses: [
      {
        id: 'e1',
        description: '火锅晚餐',
        amount: 320,
        paidBy: 'u1',
        splitBetween: ['u1', 'u2', 'u3'],
        category: 'food',
        date: '2026-05-10',
        groupId: 'g1',
      },
      {
        id: 'e2',
        description: '打车回家',
        amount: 45,
        paidBy: 'u2',
        splitBetween: ['u1', 'u2', 'u3'],
        category: 'transport',
        date: '2026-05-10',
        groupId: 'g1',
      },
    ],
  },
  {
    id: 'g2',
    name: '槟城旅行',
    emoji: '✈️',
    members: [mockUsers[0], mockUsers[1], mockUsers[3], mockUsers[4]],
    createdAt: '2026-04-20',
    expenses: [
      {
        id: 'e3',
        description: '酒店预订',
        amount: 800,
        paidBy: 'u1',
        splitBetween: ['u1', 'u2', 'u4', 'u5'],
        category: 'accommodation',
        date: '2026-04-25',
        groupId: 'g2',
      },
      {
        id: 'e4',
        description: '景点门票',
        amount: 240,
        paidBy: 'u4',
        splitBetween: ['u1', 'u2', 'u4', 'u5'],
        category: 'entertainment',
        date: '2026-04-26',
        groupId: 'g2',
      },
      {
        id: 'e5',
        description: '当地美食',
        amount: 180,
        paidBy: 'u2',
        splitBetween: ['u1', 'u2', 'u4', 'u5'],
        category: 'food',
        date: '2026-04-26',
        groupId: 'g2',
      },
    ],
  },
  {
    id: 'g3',
    name: '合租水电',
    emoji: '🏠',
    members: [mockUsers[0], mockUsers[2], mockUsers[3]],
    createdAt: '2026-03-01',
    expenses: [
      {
        id: 'e6',
        description: '5月电费',
        amount: 150,
        paidBy: 'u3',
        splitBetween: ['u1', 'u3', 'u4'],
        category: 'utilities',
        date: '2026-05-05',
        groupId: 'g3',
      },
    ],
  },
]

interface AppContextType {
  currentUser: User
  users: User[]
  groups: Group[]
  addGroup: (group: Omit<Group, 'id' | 'createdAt' | 'expenses'>) => Group
  addExpense: (groupId: string, expense: Omit<Expense, 'id'>) => void
  deleteExpense: (groupId: string, expenseId: string) => void
  getGroupById: (id: string) => Group | undefined
  getUserById: (id: string) => User | undefined
  calculateBalances: (group: Group) => Balance[]
  getTotalOwed: () => number
  getTotalOwing: () => number
}

const AppContext = createContext<AppContextType | undefined>(undefined)

export function AppProvider({ children }: { children: ReactNode }) {
  const [groups, setGroups] = useState<Group[]>(mockGroups)
  const currentUser = mockUsers[0]

  const addGroup = useCallback((groupData: Omit<Group, 'id' | 'createdAt' | 'expenses'>) => {
    const newGroup: Group = {
      ...groupData,
      id: `g${Date.now()}`,
      createdAt: new Date().toISOString().split('T')[0],
      expenses: [],
    }
    setGroups(prev => [...prev, newGroup])
    return newGroup
  }, [])

  const addExpense = useCallback((groupId: string, expenseData: Omit<Expense, 'id'>) => {
    const newExpense: Expense = {
      ...expenseData,
      id: `e${Date.now()}`,
    }
    setGroups(prev =>
      prev.map(group =>
        group.id === groupId
          ? { ...group, expenses: [...group.expenses, newExpense] }
          : group
      )
    )
  }, [])

  const deleteExpense = useCallback((groupId: string, expenseId: string) => {
    setGroups(prev =>
      prev.map(group =>
        group.id === groupId
          ? { ...group, expenses: group.expenses.filter(e => e.id !== expenseId) }
          : group
      )
    )
  }, [])

  const getGroupById = useCallback((id: string) => groups.find(g => g.id === id), [groups])
  
  const getUserById = useCallback((id: string) => mockUsers.find(u => u.id === id), [])

  const calculateBalances = useCallback((group: Group): Balance[] => {
    const balanceMap: Record<string, number> = {}
    
    // Initialize all members with 0
    group.members.forEach(member => {
      balanceMap[member.id] = 0
    })

    // Calculate net balance for each member
    group.expenses.forEach(expense => {
      const splitAmount = expense.amount / expense.splitBetween.length
      
      // Payer gets credit
      balanceMap[expense.paidBy] = (balanceMap[expense.paidBy] || 0) + expense.amount
      
      // Everyone who split owes their share
      expense.splitBetween.forEach(userId => {
        balanceMap[userId] = (balanceMap[userId] || 0) - splitAmount
      })
    })

    // Simplify debts
    const debtors: { id: string; amount: number }[] = []
    const creditors: { id: string; amount: number }[] = []

    Object.entries(balanceMap).forEach(([userId, balance]) => {
      if (balance < -0.01) {
        debtors.push({ id: userId, amount: -balance })
      } else if (balance > 0.01) {
        creditors.push({ id: userId, amount: balance })
      }
    })

    const settlements: Balance[] = []
    
    debtors.sort((a, b) => b.amount - a.amount)
    creditors.sort((a, b) => b.amount - a.amount)

    let i = 0
    let j = 0
    
    while (i < debtors.length && j < creditors.length) {
      const debtor = debtors[i]
      const creditor = creditors[j]
      const amount = Math.min(debtor.amount, creditor.amount)
      
      if (amount > 0.01) {
        settlements.push({
          from: debtor.id,
          to: creditor.id,
          amount: Math.round(amount * 100) / 100,
        })
      }
      
      debtor.amount -= amount
      creditor.amount -= amount
      
      if (debtor.amount < 0.01) i++
      if (creditor.amount < 0.01) j++
    }

    return settlements
  }, [])

  const getTotalOwed = useCallback(() => {
    let total = 0
    groups.forEach(group => {
      const balances = calculateBalances(group)
      balances.forEach(balance => {
        if (balance.to === currentUser.id) {
          total += balance.amount
        }
      })
    })
    return Math.round(total * 100) / 100
  }, [groups, calculateBalances, currentUser.id])

  const getTotalOwing = useCallback(() => {
    let total = 0
    groups.forEach(group => {
      const balances = calculateBalances(group)
      balances.forEach(balance => {
        if (balance.from === currentUser.id) {
          total += balance.amount
        }
      })
    })
    return Math.round(total * 100) / 100
  }, [groups, calculateBalances, currentUser.id])

  return (
    <AppContext.Provider
      value={{
        currentUser,
        users: mockUsers,
        groups,
        addGroup,
        addExpense,
        deleteExpense,
        getGroupById,
        getUserById,
        calculateBalances,
        getTotalOwed,
        getTotalOwing,
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export function useApp() {
  const context = useContext(AppContext)
  if (!context) {
    throw new Error('useApp must be used within AppProvider')
  }
  return context
}
