"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { useState } from "react"
import type { Plan } from "./plan-card"

interface PlanCreatorProps {
  basePlan?: Plan
  onSave: (plan: Partial<Plan>) => void
  onCancel: () => void
}

export function PlanCreator({ basePlan, onSave, onCancel }: PlanCreatorProps) {
  const [planName, setPlanName] = useState(basePlan?.name || "Custom Plan")
  const [cryptoAllocation, setCryptoAllocation] = useState(basePlan?.allocations.crypto || 40)
  const [rwaAllocation, setRwaAllocation] = useState(basePlan?.allocations.rwa || 40)
  const [stablecoinAllocation, setStablecoinAllocation] = useState(basePlan?.allocations.stablecoins || 20)

  const totalAllocation = cryptoAllocation + rwaAllocation + stablecoinAllocation

  const handleAllocationChange = (type: "crypto" | "rwa" | "stablecoins", value: number) => {
    const newValue = value

    if (type === "crypto") {
      setCryptoAllocation(newValue)
      const remaining = 100 - newValue
      const rwaRatio = rwaAllocation / (rwaAllocation + stablecoinAllocation) || 0.5
      setRwaAllocation(Math.round(remaining * rwaRatio))
      setStablecoinAllocation(remaining - Math.round(remaining * rwaRatio))
    } else if (type === "rwa") {
      setRwaAllocation(newValue)
      const remaining = 100 - newValue
      const cryptoRatio = cryptoAllocation / (cryptoAllocation + stablecoinAllocation) || 0.5
      setCryptoAllocation(Math.round(remaining * cryptoRatio))
      setStablecoinAllocation(remaining - Math.round(remaining * cryptoRatio))
    } else {
      setStablecoinAllocation(newValue)
      const remaining = 100 - newValue
      const cryptoRatio = cryptoAllocation / (cryptoAllocation + rwaAllocation) || 0.5
      setCryptoAllocation(Math.round(remaining * cryptoRatio))
      setRwaAllocation(remaining - Math.round(remaining * cryptoRatio))
    }
  }

  const handleSave = () => {
    const customPlan: Partial<Plan> = {
      name: planName,
      allocations: {
        crypto: cryptoAllocation,
        rwa: rwaAllocation,
        stablecoins: stablecoinAllocation,
      },
      description: `Custom investment plan with ${cryptoAllocation}% crypto, ${rwaAllocation}% RWA, and ${stablecoinAllocation}% stablecoins.`,
    }
    onSave(customPlan)
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Create Custom Plan</CardTitle>
        <p className="text-muted-foreground">Customize your asset allocation to match your investment goals.</p>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="plan-name">Plan Name</Label>
          <Input
            id="plan-name"
            value={planName}
            onChange={(e) => setPlanName(e.target.value)}
            placeholder="Enter plan name"
          />
        </div>

        <div className="space-y-6">
          <h4 className="font-medium">Asset Allocation</h4>

          {/* Crypto Allocation */}
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <Label>Crypto Assets</Label>
              <span className="text-sm font-medium">{cryptoAllocation}%</span>
            </div>
            <Slider
              value={[cryptoAllocation]}
              onValueChange={(value) => handleAllocationChange("crypto", value[0])}
              max={80}
              min={0}
              step={5}
              className="w-full"
            />
          </div>

          {/* RWA Allocation */}
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <Label>RWA Tokens</Label>
              <span className="text-sm font-medium">{rwaAllocation}%</span>
            </div>
            <Slider
              value={[rwaAllocation]}
              onValueChange={(value) => handleAllocationChange("rwa", value[0])}
              max={80}
              min={0}
              step={5}
              className="w-full"
            />
          </div>

          {/* Stablecoin Allocation */}
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <Label>Stablecoins</Label>
              <span className="text-sm font-medium">{stablecoinAllocation}%</span>
            </div>
            <Slider
              value={[stablecoinAllocation]}
              onValueChange={(value) => handleAllocationChange("stablecoins", value[0])}
              max={50}
              min={5}
              step={5}
              className="w-full"
            />
          </div>

          {/* Total Check */}
          <div className="flex justify-between items-center p-3 bg-muted rounded-lg">
            <span className="font-medium">Total Allocation</span>
            <span className={`font-bold ${totalAllocation === 100 ? "text-green-600" : "text-red-600"}`}>
              {totalAllocation}%
            </span>
          </div>
        </div>

        <div className="flex space-x-4 pt-4">
          <Button onClick={handleSave} disabled={totalAllocation !== 100} className="flex-1">
            Save Plan
          </Button>
          <Button variant="outline" onClick={onCancel} className="flex-1 bg-transparent">
            Cancel
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
