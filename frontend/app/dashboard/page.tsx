import { Header } from "@/components/header"
import { PortfolioOverview } from "@/components/dashboard/portfolio-overview"
import { PerformanceChart } from "@/components/dashboard/performance-chart"
import { QuickActions } from "@/components/dashboard/quick-actions"
import { RecentTransactions } from "@/components/dashboard/recent-transactions"
import { WalletStatus } from "@/components/wallet/wallet-status"

export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-8 space-y-8">
        <div className="space-y-2">
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">Monitor your automated DeFi investments and portfolio performance</p>
        </div>

        <WalletStatus />

        <PortfolioOverview />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <PerformanceChart />
          </div>
          <div className="space-y-6">
            <QuickActions />
          </div>
        </div>

        <RecentTransactions />
      </main>
    </div>
  )
}
