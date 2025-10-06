import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { TrendingUp, TrendingDown } from "lucide-react"

const mockHoldings = [
  {
    id: "1",
    symbol: "ETH",
    name: "Ethereum",
    type: "Crypto",
    balance: 35.5,
    value: 89200,
    allocation: 22.2,
    avgCost: 2100,
    currentPrice: 2513,
    pnl: 14662,
    pnlPercent: 19.7,
  },
  {
    id: "2",
    symbol: "BTC",
    name: "Bitcoin",
    type: "Crypto",
    balance: 2.4,
    value: 156800,
    allocation: 39.0,
    avgCost: 58000,
    currentPrice: 65333,
    pnl: 17600,
    pnlPercent: 12.6,
  },
  {
    id: "3",
    symbol: "RWA-BOND",
    name: "Tokenized US Treasury",
    type: "RWA",
    balance: 85000,
    value: 85000,
    allocation: 21.2,
    avgCost: 1.0,
    currentPrice: 1.0,
    pnl: 0,
    pnlPercent: 0,
  },
  {
    id: "4",
    symbol: "RWA-REIT",
    name: "Real Estate Investment Trust",
    type: "RWA",
    balance: 1200,
    value: 70840,
    allocation: 17.6,
    avgCost: 55,
    currentPrice: 59.03,
    pnl: 4840,
    pnlPercent: 7.3,
  },
  {
    id: "5",
    symbol: "USDC",
    name: "USD Coin",
    type: "Stablecoin",
    balance: 0,
    value: 0,
    allocation: 0,
    avgCost: 1.0,
    currentPrice: 1.0,
    pnl: 0,
    pnlPercent: 0,
  },
]

const typeColors = {
  Crypto: "bg-blue-100 text-blue-800",
  RWA: "bg-green-100 text-green-800",
  Stablecoin: "bg-gray-100 text-gray-800",
}

export function HoldingsTable() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Portfolio Holdings</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b text-left">
                <th className="pb-3 text-sm font-medium text-muted-foreground">Asset</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Type</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Balance</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Value</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Allocation</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Avg Cost</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">Current Price</th>
                <th className="pb-3 text-sm font-medium text-muted-foreground">P&L</th>
              </tr>
            </thead>
            <tbody>
              {mockHoldings.map((holding) => (
                <tr key={holding.id} className="border-b last:border-b-0">
                  <td className="py-4">
                    <div>
                      <div className="font-medium">{holding.symbol}</div>
                      <div className="text-sm text-muted-foreground">{holding.name}</div>
                    </div>
                  </td>
                  <td className="py-4">
                    <Badge className={typeColors[holding.type as keyof typeof typeColors]} variant="secondary">
                      {holding.type}
                    </Badge>
                  </td>
                  <td className="py-4 font-medium">
                    {holding.balance.toLocaleString(undefined, { maximumFractionDigits: 2 })}
                  </td>
                  <td className="py-4 font-medium">${holding.value.toLocaleString()}</td>
                  <td className="py-4">{holding.allocation}%</td>
                  <td className="py-4">${holding.avgCost.toLocaleString()}</td>
                  <td className="py-4">${holding.currentPrice.toLocaleString()}</td>
                  <td className="py-4">
                    <div
                      className={`flex items-center space-x-1 ${holding.pnl >= 0 ? "text-green-600" : "text-red-600"}`}
                    >
                      {holding.pnl >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                      <div>
                        <div className="font-medium">${Math.abs(holding.pnl).toLocaleString()}</div>
                        <div className="text-xs">
                          {holding.pnl >= 0 ? "+" : ""}
                          {holding.pnlPercent}%
                        </div>
                      </div>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  )
}
