"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { TrendingUp, Shield, Target, Zap } from "lucide-react"

export interface Plan {
  id: string
  name: string
  description: string
  riskLevel: "Low" | "Medium" | "High"
  expectedReturn: string
  allocations: {
    crypto: number
    rwa: number
    stablecoins: number
  }
  features: string[]
  icon: "shield" | "trending" | "target" | "zap"
}

const iconMap = {
  shield: Shield,
  trending: TrendingUp,
  target: Target,
  zap: Zap,
}

const riskColors = {
  Low: "bg-green-100 text-green-800",
  Medium: "bg-yellow-100 text-yellow-800",
  High: "bg-red-100 text-red-800",
}

interface PlanCardProps {
  plan: Plan
  onSelect: (plan: Plan) => void
  onCustomize: (plan: Plan) => void
}

export function PlanCard({ plan, onSelect, onCustomize }: PlanCardProps) {
  const IconComponent = iconMap[plan.icon]

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
              <IconComponent className="w-5 h-5 text-primary" />
            </div>
            <div>
              <CardTitle className="text-lg">{plan.name}</CardTitle>
              <Badge className={riskColors[plan.riskLevel]} variant="secondary">
                {plan.riskLevel} Risk
              </Badge>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-muted-foreground">Expected Return</div>
            <div className="text-lg font-bold text-green-600">{plan.expectedReturn}</div>
          </div>
        </div>
      </CardHeader>

      <CardContent className="space-y-6">
        <p className="text-muted-foreground">{plan.description}</p>

        {/* Allocation Breakdown */}
        <div className="space-y-3">
          <h4 className="font-medium">Asset Allocation</h4>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-sm">Crypto Assets</span>
              <span className="font-medium">{plan.allocations.crypto}%</span>
            </div>
            <div className="w-full bg-muted rounded-full h-2">
              <div className="bg-blue-500 h-2 rounded-full" style={{ width: `${plan.allocations.crypto}%` }} />
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm">RWA Tokens</span>
              <span className="font-medium">{plan.allocations.rwa}%</span>
            </div>
            <div className="w-full bg-muted rounded-full h-2">
              <div className="bg-green-500 h-2 rounded-full" style={{ width: `${plan.allocations.rwa}%` }} />
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm">Stablecoins</span>
              <span className="font-medium">{plan.allocations.stablecoins}%</span>
            </div>
            <div className="w-full bg-muted rounded-full h-2">
              <div className="bg-gray-500 h-2 rounded-full" style={{ width: `${plan.allocations.stablecoins}%` }} />
            </div>
          </div>
        </div>

        {/* Features */}
        <div className="space-y-2">
          <h4 className="font-medium">Key Features</h4>
          <ul className="space-y-1">
            {plan.features.map((feature, index) => (
              <li key={index} className="text-sm text-muted-foreground flex items-center">
                <div className="w-1.5 h-1.5 bg-primary rounded-full mr-2" />
                {feature}
              </li>
            ))}
          </ul>
        </div>

        {/* Actions */}
        <div className="flex space-x-2 pt-4">
          <Button onClick={() => onSelect(plan)} className="flex-1">
            Select Plan
          </Button>
          <Button variant="outline" onClick={() => onCustomize(plan)} className="flex-1">
            Customize
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
