"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts"
import { useState } from "react"

const mockPerformanceData = {
  "7d": [
    { date: "09/20", value: 385000 },
    { date: "09/21", value: 392000 },
    { date: "09/22", value: 388000 },
    { date: "09/23", value: 395000 },
    { date: "09/24", value: 398000 },
    { date: "09/25", value: 396000 },
    { date: "09/26", value: 401840 },
  ],
  "30d": [
    { date: "08/27", value: 365000 },
    { date: "09/03", value: 372000 },
    { date: "09/10", value: 378000 },
    { date: "09/17", value: 385000 },
    { date: "09/24", value: 398000 },
    { date: "09/26", value: 401840 },
  ],
  "90d": [
    { date: "07/01", value: 320000 },
    { date: "07/15", value: 335000 },
    { date: "08/01", value: 348000 },
    { date: "08/15", value: 362000 },
    { date: "09/01", value: 375000 },
    { date: "09/15", value: 388000 },
    { date: "09/26", value: 401840 },
  ],
}

type TimeRange = "7d" | "30d" | "90d"

export function PerformanceChart() {
  const [timeRange, setTimeRange] = useState<TimeRange>("7d")

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>Portfolio Performance</CardTitle>
        <div className="flex space-x-1">
          {(["7d", "30d", "90d"] as TimeRange[]).map((range) => (
            <Button
              key={range}
              variant={timeRange === range ? "default" : "ghost"}
              size="sm"
              onClick={() => setTimeRange(range)}
              className="text-xs"
            >
              {range}
            </Button>
          ))}
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={mockPerformanceData[timeRange]}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis dataKey="date" className="text-xs fill-muted-foreground" axisLine={false} tickLine={false} />
              <YAxis
                className="text-xs fill-muted-foreground"
                axisLine={false}
                tickLine={false}
                tickFormatter={(value) => `$${(value / 1000).toFixed(0)}K`}
              />
              <Tooltip
                formatter={(value: number) => [`$${value.toLocaleString()}`, "Portfolio Value"]}
                labelStyle={{ color: "hsl(var(--foreground))" }}
                contentStyle={{
                  backgroundColor: "hsl(var(--background))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "8px",
                }}
              />
              <Line
                type="monotone"
                dataKey="value"
                stroke="#10B981"
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4, fill: "#10B981" }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  )
}
