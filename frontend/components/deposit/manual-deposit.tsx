"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Badge } from "@/components/ui/badge"
import { Wallet, CreditCard, Building, ArrowRight } from "lucide-react"
import { useState } from "react"

const cryptoAssets = [
  { symbol: "ETH", name: "Ethereum", balance: "2.45 ETH" },
  { symbol: "BTC", name: "Bitcoin", balance: "0.15 BTC" },
  { symbol: "USDC", name: "USD Coin", balance: "1,250 USDC" },
  { symbol: "USDT", name: "Tether", balance: "500 USDT" },
]

export function ManualDeposit() {
  const [depositMethod, setDepositMethod] = useState("crypto")
  const [amount, setAmount] = useState("")
  const [selectedAsset, setSelectedAsset] = useState("")
  const [investmentPlan, setInvestmentPlan] = useState("")

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>One-Time Deposit</CardTitle>
          <p className="text-muted-foreground">Make a manual deposit to boost your investment portfolio</p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4">
            <Label>Deposit Method</Label>
            <RadioGroup value={depositMethod} onValueChange={setDepositMethod}>
              <div className="flex items-center space-x-2 p-3 border rounded-lg">
                <RadioGroupItem value="crypto" id="crypto" />
                <Label htmlFor="crypto" className="flex items-center space-x-2 cursor-pointer flex-1">
                  <Wallet className="w-4 h-4" />
                  <div>
                    <div className="font-medium">Crypto Wallet</div>
                    <div className="text-sm text-muted-foreground">Deposit from your connected wallet</div>
                  </div>
                </Label>
                <Badge variant="default">Instant</Badge>
              </div>

              <div className="flex items-center space-x-2 p-3 border rounded-lg">
                <RadioGroupItem value="bank" id="bank" />
                <Label htmlFor="bank" className="flex items-center space-x-2 cursor-pointer flex-1">
                  <Building className="w-4 h-4" />
                  <div>
                    <div className="font-medium">Bank Transfer</div>
                    <div className="text-sm text-muted-foreground">ACH transfer from your bank account</div>
                  </div>
                </Label>
                <Badge variant="secondary">1-3 days</Badge>
              </div>

              <div className="flex items-center space-x-2 p-3 border rounded-lg">
                <RadioGroupItem value="card" id="card" />
                <Label htmlFor="card" className="flex items-center space-x-2 cursor-pointer flex-1">
                  <CreditCard className="w-4 h-4" />
                  <div>
                    <div className="font-medium">Debit Card</div>
                    <div className="text-sm text-muted-foreground">Instant deposit with debit card</div>
                  </div>
                </Label>
                <Badge variant="default">Instant</Badge>
              </div>
            </RadioGroup>
          </div>

          {depositMethod === "crypto" && (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="asset">Select Asset</Label>
                <Select value={selectedAsset} onValueChange={setSelectedAsset}>
                  <SelectTrigger>
                    <SelectValue placeholder="Choose crypto asset" />
                  </SelectTrigger>
                  <SelectContent>
                    {cryptoAssets.map((asset) => (
                      <SelectItem key={asset.symbol} value={asset.symbol}>
                        <div className="flex items-center justify-between w-full">
                          <span>
                            {asset.symbol} - {asset.name}
                          </span>
                          <span className="text-muted-foreground ml-2">{asset.balance}</span>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="amount">Amount</Label>
              <Input
                id="amount"
                placeholder={depositMethod === "crypto" ? "0.5" : "1000"}
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="plan">Investment Plan</Label>
              <Select value={investmentPlan} onValueChange={setInvestmentPlan}>
                <SelectTrigger>
                  <SelectValue placeholder="Select plan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="conservative">Conservative</SelectItem>
                  <SelectItem value="balanced">Balanced</SelectItem>
                  <SelectItem value="aggressive">Aggressive</SelectItem>
                  <SelectItem value="custom">Custom Plan</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {amount && selectedAsset && investmentPlan && (
            <div className="bg-muted/50 rounded-lg p-4">
              <h4 className="font-medium mb-2">Deposit Summary</h4>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span>Amount:</span>
                  <span className="font-medium">
                    {amount} {selectedAsset}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>Investment Plan:</span>
                  <span className="font-medium capitalize">{investmentPlan}</span>
                </div>
                <div className="flex justify-between">
                  <span>Processing Fee:</span>
                  <span className="font-medium">$0.00</span>
                </div>
              </div>
            </div>
          )}

          <Button className="w-full" disabled={!amount || !investmentPlan}>
            Proceed to Deposit
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recent Deposits</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div className="flex items-center space-x-3">
                <Wallet className="w-4 h-4 text-blue-600" />
                <div>
                  <div className="font-medium">2.5 ETH</div>
                  <div className="text-sm text-muted-foreground">Sep 26, 2025 • Balanced Plan</div>
                </div>
              </div>
              <Badge variant="default">Completed</Badge>
            </div>

            <div className="flex items-center justify-between p-3 border rounded-lg">
              <div className="flex items-center space-x-3">
                <Building className="w-4 h-4 text-green-600" />
                <div>
                  <div className="font-medium">$5,000</div>
                  <div className="text-sm text-muted-foreground">Sep 24, 2025 • Conservative Plan</div>
                </div>
              </div>
              <Badge variant="default">Completed</Badge>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
