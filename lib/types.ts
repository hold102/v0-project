export interface User {
  id: string
  name: string
  avatar: string
  email?: string
}

export interface Expense {
  id: string
  description: string
  amount: number
  paidBy: string
  splitBetween: string[]
  category: ExpenseCategory
  date: string
  groupId: string
}

export interface Group {
  id: string
  name: string
  emoji: string
  members: User[]
  expenses: Expense[]
  createdAt: string
}

export interface Balance {
  from: string
  to: string
  amount: number
}

export type ExpenseCategory = 
  | 'food'
  | 'transport'
  | 'entertainment'
  | 'shopping'
  | 'accommodation'
  | 'utilities'
  | 'other'

export const categoryConfig: Record<ExpenseCategory, { label: string; emoji: string; color: string }> = {
  food: { label: '餐饮', emoji: '🍜', color: 'bg-orange-100 text-orange-700' },
  transport: { label: '交通', emoji: '🚗', color: 'bg-blue-100 text-blue-700' },
  entertainment: { label: '娱乐', emoji: '🎬', color: 'bg-pink-100 text-pink-700' },
  shopping: { label: '购物', emoji: '🛍️', color: 'bg-purple-100 text-purple-700' },
  accommodation: { label: '住宿', emoji: '🏨', color: 'bg-teal-100 text-teal-700' },
  utilities: { label: '水电', emoji: '💡', color: 'bg-yellow-100 text-yellow-700' },
  other: { label: '其他', emoji: '📦', color: 'bg-gray-100 text-gray-700' },
}
