import { Header } from "@/components/header"
import { HoldingsTable } from "@/components/portfolio/holdings-table"
import { PerformanceAnalytics } from "@/components/portfolio/performance-analytics"
import { RebalancingStatus } from "@/components/portfolio/rebalancing-status"
import { TransactionHistory } from "@/components/portfolio/transaction-history"

export default function PortfolioPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-8 space-y-8">
        <div className="space-y-2">
          <h1 className="text-3xl font-bold">Portfolio Management</h1>
          <p className="text-muted-foreground">
            Detailed view of your holdings, performance analytics, and rebalancing status
          </p>
        </div>

        <PerformanceAnalytics />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <HoldingsTable />
          </div>
          <div>
            <RebalancingStatus />
          </div>
        </div>

        <TransactionHistory />
      </main>
    </div>
  )
}
