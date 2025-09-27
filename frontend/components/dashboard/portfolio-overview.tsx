import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { TrendingUp, TrendingDown } from "lucide-react"

const mockPortfolioData = {
  totalValue: 401840,
  dailyChange: 16750,
  dailyChangePercent: 4.2,
  allocations: [
    { name: "ETH", value: 89200, percentage: 22.2, color: "#8B5CF6" },
    { name: "BTC", value: 156800, percentage: 39.0, color: "#F59E0B" },
    { name: "RWA Tokens", value: 155840, percentage: 38.8, color: "#10B981" },
  ],
}

export function PortfolioOverview() {
  const isPositive = mockPortfolioData.dailyChangePercent > 0

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {/* Total Portfolio Value */}
      <Card className="lg:col-span-2">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Total Portfolio Value</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="text-3xl font-bold">${mockPortfolioData.totalValue.toLocaleString()}</div>
            <div className={`flex items-center space-x-1 text-sm ${isPositive ? "text-green-600" : "text-red-600"}`}>
              {isPositive ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
              <span>
                ${Math.abs(mockPortfolioData.dailyChange).toLocaleString()}({isPositive ? "+" : ""}
                {mockPortfolioData.dailyChangePercent}%)
              </span>
              <span className="text-muted-foreground">today</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Asset Allocation */}
      <Card className="lg:col-span-2">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Asset Allocation</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {mockPortfolioData.allocations.map((asset, index) => (
              <div key={index} className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: asset.color }} />
                  <span className="text-sm font-medium">{asset.name}</span>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium">${asset.value.toLocaleString()}</div>
                  <div className="text-xs text-muted-foreground">{asset.percentage}%</div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
