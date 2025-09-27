import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowUpRight, ArrowDownLeft, Repeat } from "lucide-react"

const mockTransactions = [
  {
    id: "1",
    date: "2025-09-26",
    asset: "ETH",
    action: "Deposit",
    amount: 2.5,
    value: 6250,
    status: "Completed",
  },
  {
    id: "2",
    date: "2025-09-26",
    asset: "BTC",
    action: "Auto-Invest",
    amount: 0.15,
    value: 9750,
    status: "Completed",
  },
  {
    id: "3",
    date: "2025-09-25",
    asset: "RWA-BOND",
    action: "Rebalance",
    amount: 1000,
    value: 1000,
    status: "Completed",
  },
  {
    id: "4",
    date: "2025-09-25",
    asset: "USDC",
    action: "Deposit",
    amount: 5000,
    value: 5000,
    status: "Pending",
  },
  {
    id: "5",
    date: "2025-09-24",
    asset: "ETH",
    action: "Auto-Invest",
    amount: 1.8,
    value: 4500,
    status: "Completed",
  },
]

function getActionIcon(action: string) {
  switch (action) {
    case "Deposit":
      return <ArrowUpRight className="w-4 h-4 text-green-600" />
    case "Withdraw":
      return <ArrowDownLeft className="w-4 h-4 text-red-600" />
    case "Auto-Invest":
    case "Rebalance":
      return <Repeat className="w-4 h-4 text-blue-600" />
    default:
      return <Repeat className="w-4 h-4 text-muted-foreground" />
  }
}

export function RecentTransactions() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Transactions</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {mockTransactions.map((transaction) => (
            <div key={transaction.id} className="flex items-center justify-between py-2">
              <div className="flex items-center space-x-3">
                {getActionIcon(transaction.action)}
                <div>
                  <div className="font-medium text-sm">
                    {transaction.action} {transaction.asset}
                  </div>
                  <div className="text-xs text-muted-foreground">{new Date(transaction.date).toLocaleDateString()}</div>
                </div>
              </div>

              <div className="text-right space-y-1">
                <div className="font-medium text-sm">${transaction.value.toLocaleString()}</div>
                <Badge variant={transaction.status === "Completed" ? "default" : "secondary"} className="text-xs">
                  {transaction.status}
                </Badge>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
