import { Header } from "@/components/header"
import { DepositTabs } from "@/components/deposit/deposit-tabs"

export default function DepositPage() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold">Deposit & Salary Setup</h1>
            <p className="text-muted-foreground">
              Configure automatic salary investments or make manual deposits to grow your portfolio
            </p>
          </div>

          <DepositTabs />
        </div>
      </main>
    </div>
  )
}
