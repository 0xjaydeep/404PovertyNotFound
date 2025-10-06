"use client";

import { Header } from "@/components/header";
import { PlanCard, type Plan } from "@/components/plans/plan-card";
import { RiskAssessment } from "@/components/plans/risk-assessment";
import { PlanCreator } from "@/components/plans/plan-creator";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const mockPlans: Plan[] = [
  {
    id: "conservative",
    name: "Conservative",
    description:
      "Low-risk strategy focused on stable returns with minimal volatility. Perfect for risk-averse investors.",
    riskLevel: "Low",
    expectedReturn: "8-12%",
    allocations: {
      crypto: 20,
      rwa: 60,
      stablecoins: 20,
    },
    features: [
      "Low volatility portfolio",
      "Focus on stable RWA tokens",
      "Regular rebalancing",
      "Capital preservation priority",
    ],
    icon: "shield",
  },
  {
    id: "balanced",
    name: "Balanced",
    description:
      "Moderate risk approach balancing growth potential with stability. Ideal for most investors.",
    riskLevel: "Medium",
    expectedReturn: "12-18%",
    allocations: {
      crypto: 40,
      rwa: 45,
      stablecoins: 15,
    },
    features: [
      "Balanced risk-reward ratio",
      "Diversified asset mix",
      "Quarterly rebalancing",
      "Growth with stability",
    ],
    icon: "trending",
  },
  {
    id: "aggressive",
    name: "Aggressive",
    description:
      "High-growth strategy for maximum returns. Suitable for experienced investors with high risk tolerance.",
    riskLevel: "High",
    expectedReturn: "18-25%",
    allocations: {
      crypto: 65,
      rwa: 25,
      stablecoins: 10,
    },
    features: [
      "Maximum growth potential",
      "High crypto allocation",
      "Dynamic rebalancing",
      "Long-term focus",
    ],
    icon: "zap",
  },
  {
    id: "RWA",
    name: "RWA",
    description: "Money Market",
    riskLevel: "Medium",
    expectedReturn: "14-20%",
    allocations: {
      crypto: 75,
      rwa: 15,
      stablecoins: 10,
    },
    features: [
      "Automatic risk adjustment",
      "Target date optimization",
      "Glide path strategy",
      "Set-and-forget approach",
    ],
    icon: "target",
  },
];

export default function PlansPage() {
  const [showRiskAssessment, setShowRiskAssessment] = useState(false);
  const [showPlanCreator, setShowPlanCreator] = useState(false);
  const [selectedBasePlan, setSelectedBasePlan] = useState<Plan | undefined>();
  const [recommendedPlan, setRecommendedPlan] = useState<string | null>(null);

  const handlePlanSelect = (plan: Plan) => {
    console.log("Selected plan:", plan.name);
    // Here you would typically navigate to a confirmation page or start the investment process
  };

  const handlePlanCustomize = (plan: Plan) => {
    setSelectedBasePlan(plan);
    setShowPlanCreator(true);
  };

  const handleRiskAssessmentComplete = (
    riskProfile: "Conservative" | "Balanced" | "Aggressive"
  ) => {
    setRecommendedPlan(riskProfile.toLowerCase());
    setShowRiskAssessment(false);
  };

  const handlePlanCreatorSave = (customPlan: Partial<Plan>) => {
    console.log("Custom plan created:", customPlan);
    setShowPlanCreator(false);
    setSelectedBasePlan(undefined);
    // Here you would typically save the custom plan
  };

  const handlePlanCreatorCancel = () => {
    setShowPlanCreator(false);
    setSelectedBasePlan(undefined);
  };

  if (showRiskAssessment) {
    return (
      <div className="min-h-screen bg-background">
        <Header />
        <main className="container mx-auto px-4 py-8">
          <div className="max-w-2xl mx-auto">
            <RiskAssessment
              onComplete={handleRiskAssessmentComplete}
              onSkip={() => setShowRiskAssessment(false)}
            />
          </div>
        </main>
      </div>
    );
  }

  if (showPlanCreator) {
    return (
      <div className="min-h-screen bg-background">
        <Header />
        <main className="container mx-auto px-4 py-8">
          <div className="max-w-2xl mx-auto">
            <PlanCreator
              basePlan={selectedBasePlan}
              onSave={handlePlanCreatorSave}
              onCancel={handlePlanCreatorCancel}
            />
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-8 space-y-8">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold">Investment Plans</h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Choose from our pre-built investment strategies or create your own
            custom plan
          </p>
          <div className="flex justify-center space-x-4">
            <Button onClick={() => setShowRiskAssessment(true)}>
              Take Risk Assessment
            </Button>
            <Button variant="outline" onClick={() => setShowPlanCreator(true)}>
              Create Custom Plan
            </Button>
          </div>
        </div>

        {recommendedPlan && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
            <p className="text-green-800">
              <strong>Recommended for you:</strong> Based on your risk
              assessment, we recommend the{" "}
              <strong className="capitalize">{recommendedPlan}</strong> plan.
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {mockPlans.map((plan) => (
            <PlanCard
              key={plan.id}
              plan={plan}
              onSelect={handlePlanSelect}
              onCustomize={handlePlanCustomize}
            />
          ))}
        </div>
      </main>
    </div>
  );
}
