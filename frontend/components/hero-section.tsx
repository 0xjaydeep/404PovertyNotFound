import { Button } from "@/components/ui/button";
import { ArrowRight, TrendingUp } from "lucide-react";

export function HeroSection() {
  return (
    <section className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <div className="text-center space-y-8">
          {/* Announcement Banner */}
          <div className="inline-flex items-center space-x-2 bg-success/10 text-success px-4 py-2 rounded-full text-sm font-medium">
            {/* <TrendingUp className="w-4 h-4" />
            <span>Announcing $20M in Seed & Series A Funding</span>
            <ArrowRight className="w-4 h-4" /> */}
          </div>

          {/* Main Headline */}
          <div className="space-y-6">
            <h1 className="text-5xl md:text-7xl font-bold text-balance leading-tight">
              Automated Salary-Based
              <br />
              <span className="text-muted-foreground">DeFi Investment</span>
            </h1>

            <p className="text-xl text-muted-foreground max-w-3xl mx-auto text-balance">
              Streamline your wealth building with automated salary deductions
              invested in Real World Assets. Our institutional-grade platform
              bridges traditional finance with DeFi opportunities.
            </p>
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Button size="lg" className="px-8">
              Connect Wallet
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
            <Button variant="outline" size="lg" className="px-8 bg-transparent">
              View Demo
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}
