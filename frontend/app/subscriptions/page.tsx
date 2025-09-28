import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { TrendingUp, TrendingDown, DollarSign, Calendar } from "lucide-react";

export default function SubscriptionsPage() {
  // Mock data - in real app, this would come from your smart contracts
  const subscriptions = [
    {
      id: 1,
      name: "Aggressive Growth",
      risk: "High",
      status: "Active",
      invested: 2.5,
      returns: 0.8,
      returnPercentage: 32,
      nextDeposit: "2025-09-30",
      planType: "Aggressive",
      allocations: [
        { asset: "ETH", percentage: 60 },
        { asset: "BTC", percentage: 30 },
        { asset: "Altcoins", percentage: 10 },
      ],
    },
    {
      id: 2,
      name: "Balanced Portfolio",
      risk: "Medium",
      status: "Active",
      invested: 1.8,
      returns: 0.2,
      returnPercentage: 11,
      nextDeposit: "2025-09-30",
      planType: "Balanced",
      allocations: [
        { asset: "ETH", percentage: 40 },
        { asset: "BTC", percentage: 30 },
        { asset: "Stablecoins", percentage: 30 },
      ],
    },
  ];

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case "High":
        return "destructive";
      case "Medium":
        return "default";
      case "Low":
        return "secondary";
      default:
        return "default";
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "Active":
        return "default";
      case "Paused":
        return "secondary";
      case "Completed":
        return "outline";
      default:
        return "default";
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">My Subscriptions</h1>
        <p className="text-muted-foreground">
          Manage your active investment plans and track performance
        </p>
      </div>

      <div className="grid gap-6">
        {subscriptions.map((subscription) => (
          <Card key={subscription.id} className="w-full">
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle className="text-xl">{subscription.name}</CardTitle>
                  <CardDescription className="mt-1">
                    {subscription.planType} Investment Plan
                  </CardDescription>
                </div>
                <div className="flex gap-2">
                  <Badge variant={getRiskColor(subscription.risk)}>
                    {subscription.risk} Risk
                  </Badge>
                  <Badge variant={getStatusColor(subscription.status)}>
                    {subscription.status}
                  </Badge>
                </div>
              </div>
            </CardHeader>

            <CardContent className="space-y-6">
              {/* Performance Overview */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <DollarSign className="h-4 w-4" />
                    Total Invested
                  </div>
                  <div className="text-2xl font-bold">
                    ${subscription.invested.toFixed(2)}
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <TrendingUp className="h-4 w-4" />
                    Returns
                  </div>
                  <div className="text-2xl font-bold text-green-600">
                    +${subscription.returns.toFixed(2)}
                  </div>
                  <div className="text-sm text-green-600">
                    +{subscription.returnPercentage}%
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    Next Deposit
                  </div>
                  <div className="text-lg font-semibold">
                    {subscription.nextDeposit}
                  </div>
                </div>
              </div>

              {/* Performance Progress */}
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Performance Progress</span>
                  <span>{subscription.returnPercentage}%</span>
                </div>
                <Progress
                  value={subscription.returnPercentage}
                  className="h-2"
                />
              </div>

              {/* Asset Allocation */}
              <div className="space-y-3">
                <h4 className="font-semibold">Asset Allocation</h4>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {subscription.allocations.map((allocation, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-3 bg-muted rounded-lg"
                    >
                      <span className="font-medium">{allocation.asset}</span>
                      <span className="text-sm text-muted-foreground">
                        {allocation.percentage}%
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3 pt-4">
                <Button variant="outline" size="sm">
                  View Details
                </Button>
                <Button variant="outline" size="sm">
                  Modify Plan
                </Button>
                <Button variant="outline" size="sm">
                  Pause Subscription
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {subscriptions.length === 0 && (
        <div className="text-center py-12">
          <div className="text-muted-foreground mb-4">
            <TrendingUp className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <h3 className="text-lg font-semibold mb-2">
              No Active Subscriptions
            </h3>
            <p>You haven't subscribed to any investment plans yet.</p>
          </div>
          <Button asChild>
            <a href="/plans">Browse Investment Plans</a>
          </Button>
        </div>
      )}
    </div>
  );
}
