"use client"

import { useAccount, useBalance } from "wagmi"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Wallet, AlertCircle } from "lucide-react"

// Mock data for demonstration since we can't connect to real contracts in Next.js
const MOCK_PORTFOLIO_DATA = {
  portfolioValue: 401840,
  investedAmount: 365000,
}

export function WalletStatus() {
  const { address, isConnected, chain } = useAccount()
  const { data: balance } = useBalance({ address })

  if (!isConnected) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <AlertCircle className="w-5 h-5 text-yellow-600" />
            <span>Wallet Not Connected</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            Connect your wallet to view your DeFi investment portfolio and make transactions.
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center space-x-2">
          <Wallet className="w-5 h-5 text-green-600" />
          <span>Wallet Connected</span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="text-sm text-muted-foreground">Address</div>
            <div className="font-mono text-sm">
              {address?.slice(0, 6)}...{address?.slice(-4)}
            </div>
          </div>
          <div>
            <div className="text-sm text-muted-foreground">Network</div>
            <Badge variant="default">{chain?.name || "Unknown"}</Badge>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <div className="text-sm text-muted-foreground">Wallet Balance</div>
            <div className="font-bold">
              {balance ? `${Number(balance.formatted).toFixed(4)} ${balance.symbol}` : "0.0000 ETH"}
            </div>
          </div>
          <div>
            <div className="text-sm text-muted-foreground">Portfolio Value</div>
            <div className="font-bold">${MOCK_PORTFOLIO_DATA.portfolioValue.toLocaleString()}</div>
          </div>
          <div>
            <div className="text-sm text-muted-foreground">Invested Amount</div>
            <div className="font-bold">${MOCK_PORTFOLIO_DATA.investedAmount.toLocaleString()}</div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
