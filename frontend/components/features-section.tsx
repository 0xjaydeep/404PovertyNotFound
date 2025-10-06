import { Card, CardContent } from "@/components/ui/card"
import { Zap, Shield, BarChart3, Repeat, DollarSign, Users } from "lucide-react"

const features = [
  {
    icon: Zap,
    title: "Automated Execution",
    description:
      "Streamline fixed income trading with automated execution. Set your parameters and let our algorithms handle the rest.",
  },
  {
    icon: Shield,
    title: "Risk Management",
    description:
      "Create custom risk policies, monitor open orders, and take control of your investment strategy with institutional-grade tools.",
  },
  {
    icon: BarChart3,
    title: "Custom Strategies",
    description:
      "Build ladders, automate reinvestment, and rebalancing. Create sophisticated investment strategies tailored to your goals.",
  },
  {
    icon: Repeat,
    title: "Auto-Rebalancing",
    description:
      "Maintain your target allocation automatically. Our system rebalances your portfolio based on market conditions and your preferences.",
  },
  {
    icon: DollarSign,
    title: "Real World Assets",
    description:
      "Invest in tokenized stocks, bonds, ETFs, and other traditional assets through our compliant DeFi infrastructure.",
  },
  {
    icon: Users,
    title: "Institutional Grade",
    description:
      "Built for scale with enterprise security, compliance features, and the reliability institutions demand.",
  },
]

export function FeaturesSection() {
  return (
    <section className="py-24 px-4 bg-muted/30">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center space-y-4 mb-16">
          <h2 className="text-4xl font-bold text-balance">Everything you need to automate your investments</h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto text-balance">
            Professional-grade tools designed for both individual investors and institutions
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <Card key={index} className="border-0 shadow-sm hover:shadow-md transition-shadow">
              <CardContent className="p-8">
                <div className="space-y-4">
                  <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center">
                    <feature.icon className="w-6 h-6 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold">{feature.title}</h3>
                  <p className="text-muted-foreground leading-relaxed">{feature.description}</p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
