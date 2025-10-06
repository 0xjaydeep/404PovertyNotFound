import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { TrendingUp, Activity, Target, BarChart3 } from "lucide-react"

const mockAnalytics = {
  totalReturn: {
    value: 37102,
    percentage: 10.2,
  },
  volatility: 18.5,
  sharpeRatio: 1.34,
  maxDrawdown: -8.2,
  winRate: 68.5,
  avgHoldingPeriod: 45,
}

export function PerformanceAnalytics() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Return</CardTitle>
          <TrendingUp className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-green-600">+${mockAnalytics.totalReturn.value.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground">+{mockAnalytics.totalReturn.percentage}% since inception</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Volatility</CardTitle>
          <Activity className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{mockAnalytics.volatility}%</div>
          <p className="text-xs text-muted-foreground">30-day rolling volatility</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Sharpe Ratio</CardTitle>
          <Target className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-green-600">{mockAnalytics.sharpeRatio}</div>
          <p className="text-xs text-muted-foreground">Risk-adjusted returns</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Max Drawdown</CardTitle>
          <BarChart3 className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-red-600">{mockAnalytics.maxDrawdown}%</div>
          <p className="text-xs text-muted-foreground">Largest peak-to-trough decline</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Win Rate</CardTitle>
          <Target className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{mockAnalytics.winRate}%</div>
          <p className="text-xs text-muted-foreground">Profitable positions</p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Avg Holding Period</CardTitle>
          <Activity className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{mockAnalytics.avgHoldingPeriod} days</div>
          <p className="text-xs text-muted-foreground">Average position duration</p>
        </CardContent>
      </Card>
    </div>
  )
}
