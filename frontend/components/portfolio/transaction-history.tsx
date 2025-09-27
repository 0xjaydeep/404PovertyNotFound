"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ArrowUpRight, ArrowDownLeft, Repeat, DollarSign } from "lucide-react"
import { useState } from "react"

const mockTransactionHistory = [
  {
    id: "1",
    date: "2025-09-26T10:30:00Z",
    type: "Deposit",
    asset: "ETH",
    amount: 2.5,
    value: 6250,
    price: 2500,
    status: "Completed",
    txHash: "0x1234...5678",
  },
  {
    id: "2",
    date: "2025-09-26T09:15:00Z",
    type: "Auto-Invest",
    asset: "BTC",
    amount: 0.15,
    value: 9750,
    price: 65000,
    status: "Completed",
    txHash: "0x2345...6789",
  },
  {
    id: "3",
    date: "2025-09-25T14:20:00Z",
    type: "Rebalance",
    asset: "RWA-BOND",
    amount: 1000,
    value: 1000,
    price: 1.0,
    status: "Completed",
    txHash: "0x3456...7890",
  },
  {
    id: "4",
    date: "2025-09-25T08:45:00Z",
    type: "Salary Deposit",
    asset: "USDC",
    amount: 5000,
    value: 5000,
    price: 1.0,
    status: "Completed",
    txHash: "0x4567...8901",
  },
  {
    id: "5",
    date: "2025-09-24T16:30:00Z",
    type: "Auto-Invest",
    asset: "ETH",
    amount: 1.8,
    value: 4500,
    price: 2500,
    status: "Completed",
    txHash: "0x5678...9012",
  },
  {
    id: "6",
    date: "2025-09-24T11:15:00Z",
    type: "Withdraw",
    asset: "USDC",
    amount: 2000,
    value: 2000,
    price: 1.0,
    status: "Completed",
    txHash: "0x6789...0123",
  },
  {
    id: "7",
    date: "2025-09-23T13:45:00Z",
    type: "Rebalance",
    asset: "RWA-REIT",
    amount: 50,
    value: 2950,
    price: 59.0,
    status: "Completed",
    txHash: "0x7890...1234",
  },
  {
    id: "8",
    date: "2025-09-22T09:30:00Z",
    type: "Auto-Invest",
    asset: "BTC",
    amount: 0.08,
    value: 5200,
    price: 65000,
    status: "Completed",
    txHash: "0x8901...2345",
  },
]

function getTransactionIcon(type: string) {
  switch (type) {
    case "Deposit":
    case "Salary Deposit":
      return <ArrowUpRight className="w-4 h-4 text-green-600" />
    case "Withdraw":
      return <ArrowDownLeft className="w-4 h-4 text-red-600" />
    case "Auto-Invest":
    case "Rebalance":
      return <Repeat className="w-4 h-4 text-blue-600" />
    default:
      return <DollarSign className="w-4 h-4 text-muted-foreground" />
  }
}

export function TransactionHistory() {
  const [showAll, setShowAll] = useState(false)
  const displayedTransactions = showAll ? mockTransactionHistory : mockTransactionHistory.slice(0, 5)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Transaction History</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {displayedTransactions.map((transaction) => (
            <div key={transaction.id} className="flex items-center justify-between py-3 border-b last:border-b-0">
              <div className="flex items-center space-x-4">
                {getTransactionIcon(transaction.type)}
                <div>
                  <div className="font-medium text-sm">
                    {transaction.type} {transaction.asset}
                  </div>
                  <div className="text-xs text-muted-foreground">{new Date(transaction.date).toLocaleString()}</div>
                </div>
              </div>

              <div className="text-right space-y-1">
                <div className="font-medium text-sm">
                  {transaction.amount.toLocaleString(undefined, { maximumFractionDigits: 4 })} {transaction.asset}
                </div>
                <div className="text-xs text-muted-foreground">${transaction.value.toLocaleString()}</div>
              </div>

              <div className="text-right space-y-1">
                <Badge variant="default" className="text-xs">
                  {transaction.status}
                </Badge>
                <div className="text-xs text-muted-foreground">
                  {transaction.txHash.slice(0, 6)}...{transaction.txHash.slice(-4)}
                </div>
              </div>
            </div>
          ))}
        </div>

        {!showAll && mockTransactionHistory.length > 5 && (
          <div className="pt-4">
            <Button variant="outline" onClick={() => setShowAll(true)} className="w-full bg-transparent">
              Show All Transactions ({mockTransactionHistory.length - 5} more)
            </Button>
          </div>
        )}

        {showAll && (
          <div className="pt-4">
            <Button variant="outline" onClick={() => setShowAll(false)} className="w-full bg-transparent">
              Show Less
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
