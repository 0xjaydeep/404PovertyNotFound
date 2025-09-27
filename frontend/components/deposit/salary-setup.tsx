"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Badge } from "@/components/ui/badge"
import { Calendar, DollarSign, Repeat, Shield } from "lucide-react"
import { useState } from "react"

export function SalarySetup() {
  const [isEnabled, setIsEnabled] = useState(false)
  const [salaryAmount, setSalaryAmount] = useState("")
  const [investmentPercentage, setInvestmentPercentage] = useState("")
  const [frequency, setFrequency] = useState("")
  const [startDate, setStartDate] = useState("")

  const calculateMonthlyInvestment = () => {
    const salary = Number.parseFloat(salaryAmount) || 0
    const percentage = Number.parseFloat(investmentPercentage) || 0
    return (salary * percentage) / 100
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center space-x-2">
                <Repeat className="w-5 h-5" />
                <span>Automated Salary Investment</span>
              </CardTitle>
              <p className="text-muted-foreground mt-1">
                Automatically invest a portion of your salary into your chosen investment plan
              </p>
            </div>
            <Switch checked={isEnabled} onCheckedChange={setIsEnabled} />
          </div>
        </CardHeader>

        {isEnabled && (
          <CardContent className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label htmlFor="salary">Monthly Salary</Label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="salary"
                    placeholder="5000"
                    value={salaryAmount}
                    onChange={(e) => setSalaryAmount(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="percentage">Investment Percentage</Label>
                <div className="relative">
                  <Input
                    id="percentage"
                    placeholder="15"
                    value={investmentPercentage}
                    onChange={(e) => setInvestmentPercentage(e.target.value)}
                    className="pr-8"
                  />
                  <span className="absolute right-3 top-3 text-sm text-muted-foreground">%</span>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="frequency">Payment Frequency</Label>
                <Select value={frequency} onValueChange={setFrequency}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select frequency" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="weekly">Weekly</SelectItem>
                    <SelectItem value="bi-weekly">Bi-weekly</SelectItem>
                    <SelectItem value="monthly">Monthly</SelectItem>
                    <SelectItem value="semi-monthly">Semi-monthly</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="start-date">Start Date</Label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="start-date"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>
            </div>

            {salaryAmount && investmentPercentage && (
              <div className="bg-muted/50 rounded-lg p-4">
                <h4 className="font-medium mb-2">Investment Summary</h4>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-muted-foreground">Monthly Investment:</span>
                    <div className="font-bold text-lg">${calculateMonthlyInvestment().toLocaleString()}</div>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Annual Investment:</span>
                    <div className="font-bold text-lg">${(calculateMonthlyInvestment() * 12).toLocaleString()}</div>
                  </div>
                </div>
              </div>
            )}

            <div className="flex items-center space-x-2 p-3 bg-blue-50 rounded-lg">
              <Shield className="w-4 h-4 text-blue-600" />
              <span className="text-sm text-blue-800">
                Your salary information is encrypted and secure. We partner with leading payroll providers.
              </span>
            </div>

            <Button className="w-full">Setup Automatic Investment</Button>
          </CardContent>
        )}
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Current Salary Investments</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div>
                <div className="font-medium">Conservative Plan</div>
                <div className="text-sm text-muted-foreground">$750/month • Active since Jan 2025</div>
              </div>
              <Badge variant="default">Active</Badge>
            </div>

            <div className="text-center py-8 text-muted-foreground">
              <p>No other automatic investments configured</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
