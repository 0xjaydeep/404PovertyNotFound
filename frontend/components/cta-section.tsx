import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowRight, Smartphone } from "lucide-react"

export function CTASection() {
  return (
    <section className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <Card className="bg-gradient-to-r from-primary to-primary/80 border-0 text-primary-foreground overflow-hidden">
          <CardContent className="p-0">
            <div className="grid grid-cols-1 lg:grid-cols-2 items-center">
              <div className="p-12 space-y-6">
                <h2 className="text-4xl font-bold text-balance">Finance without the middleman.</h2>
                <p className="text-xl opacity-90 text-balance">
                  Do more with your digital assets. The self-custody platform that brings the best of DeFi directly to
                  you.
                </p>
                <Button
                  size="lg"
                  variant="secondary"
                  className="bg-primary-foreground text-primary hover:bg-primary-foreground/90"
                >
                  Join the waitlist
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              </div>

              <div className="relative p-12 flex justify-center">
                <div className="relative">
                  <div className="w-64 h-96 bg-primary-foreground rounded-3xl shadow-2xl flex items-center justify-center">
                    <div className="w-56 h-88 bg-background rounded-2xl p-4 space-y-4">
                      <div className="flex items-center justify-between">
                        <div className="text-xs text-muted-foreground">Portfolio Value</div>
                        <div className="text-xs text-success">+4.2%</div>
                      </div>
                      <div className="text-2xl font-bold text-foreground">$401.84K</div>
                      <div className="h-32 bg-success/10 rounded-lg flex items-end p-2">
                        <div className="w-full h-20 bg-success/20 rounded"></div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">ETH</span>
                          <span className="font-medium">$89.2K</span>
                        </div>
                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">BTC</span>
                          <span className="font-medium">$156.8K</span>
                        </div>
                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">RWA Tokens</span>
                          <span className="font-medium">$155.8K</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <Smartphone className="absolute -top-2 -right-2 w-6 h-6 text-primary-foreground/60" />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </section>
  )
}
