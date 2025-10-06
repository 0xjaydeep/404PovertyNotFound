import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Plus, ArrowUpRight, ArrowDownLeft, Settings } from "lucide-react"
import Link from "next/link"

export function QuickActions() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Quick Actions</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Link href="/deposit">
          <Button className="w-full justify-start" size="lg">
            <ArrowUpRight className="w-4 h-4 mr-2" />
            Deposit Funds
          </Button>
        </Link>

        <Button variant="outline" className="w-full justify-start bg-transparent" size="lg">
          <ArrowDownLeft className="w-4 h-4 mr-2" />
          Withdraw
        </Button>

        <Link href="/plans">
          <Button variant="outline" className="w-full justify-start bg-transparent" size="lg">
            <Plus className="w-4 h-4 mr-2" />
            Create Plan
          </Button>
        </Link>

        <Button variant="ghost" className="w-full justify-start" size="lg">
          <Settings className="w-4 h-4 mr-2" />
          Settings
        </Button>
      </CardContent>
    </Card>
  )
}
