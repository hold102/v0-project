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
  food: { label: '餐饮', emoji: '🍜', color: 'bg-amber-100 border border-amber-200' },
  transport: { label: '交通', emoji: '🚗', color: 'bg-sky-100 border border-sky-200' },
  entertainment: { label: '娱乐', emoji: '🎬', color: 'bg-rose-100 border border-rose-200' },
  shopping: { label: '购物', emoji: '🛍️', color: 'bg-violet-100 border border-violet-200' },
  accommodation: { label: '住宿', emoji: '🏨', color: 'bg-emerald-100 border border-emerald-200' },
  utilities: { label: '水电', emoji: '💡', color: 'bg-yellow-100 border border-yellow-200' },
  other: { label: '其他', emoji: '📦', color: 'bg-slate-100 border border-slate-200' },
}
