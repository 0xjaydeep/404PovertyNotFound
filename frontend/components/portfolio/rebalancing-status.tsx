import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { AlertTriangle, CheckCircle, Clock } from "lucide-react"

const mockRebalancingData = {
  nextRebalance: "2025-10-01",
  daysUntilRebalance: 5,
  status: "On Track",
  driftThreshold: 5,
  currentDrifts: [
    { asset: "BTC", target: 40, current: 39.0, drift: -1.0 },
    { asset: "ETH", target: 20, current: 22.2, drift: 2.2 },
    { asset: "RWA", target: 35, current: 38.8, drift: 3.8 },
    { asset: "Stablecoins", target: 5, current: 0, drift: -5.0 },
  ],
}

export function RebalancingStatus() {
  const maxDrift = Math.max(...mockRebalancingData.currentDrifts.map((d) => Math.abs(d.drift)))
  const needsRebalancing = maxDrift > mockRebalancingData.driftThreshold

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>Rebalancing Status</CardTitle>
        <Badge variant={needsRebalancing ? "destructive" : "default"} className="flex items-center space-x-1">
          {needsRebalancing ? <AlertTriangle className="w-3 h-3" /> : <CheckCircle className="w-3 h-3" />}
          <span>{needsRebalancing ? "Needs Rebalancing" : "On Track"}</span>
        </Badge>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Clock className="w-4 h-4 text-muted-foreground" />
            <span className="text-sm">Next scheduled rebalance</span>
          </div>
          <div className="text-right">
            <div className="font-medium">{new Date(mockRebalancingData.nextRebalance).toLocaleDateString()}</div>
            <div className="text-xs text-muted-foreground">{mockRebalancingData.daysUntilRebalance} days</div>
          </div>
        </div>

        <div className="space-y-4">
          <h4 className="font-medium">Current Allocation Drift</h4>
          {mockRebalancingData.currentDrifts.map((drift) => (
            <div key={drift.asset} className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium">{drift.asset}</span>
                <div className="text-right">
                  <span className="text-sm">
                    {drift.current}% / {drift.target}%
                  </span>
                  <span
                    className={`ml-2 text-xs ${
                      Math.abs(drift.drift) > mockRebalancingData.driftThreshold
                        ? "text-red-600"
                        : "text-muted-foreground"
                    }`}
                  >
                    ({drift.drift > 0 ? "+" : ""}
                    {drift.drift.toFixed(1)}%)
                  </span>
                </div>
              </div>
              <Progress
                value={Math.abs(drift.drift)}
                max={10}
                className={`h-2 ${
                  Math.abs(drift.drift) > mockRebalancingData.driftThreshold ? "bg-red-100" : "bg-muted"
                }`}
              />
            </div>
          ))}
        </div>

        <div className="pt-4 space-y-2">
          <Button className="w-full" disabled={!needsRebalancing}>
            Rebalance Now
          </Button>
          <Button variant="outline" className="w-full bg-transparent">
            Schedule Rebalancing
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
