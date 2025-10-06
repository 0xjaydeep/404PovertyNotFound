import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-border bg-muted/30">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="space-y-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                <span className="text-primary-foreground font-bold text-sm">
                  DI
                </span>
              </div>
              <span className="font-semibold text-xl">DIP</span>
            </div>
            <p className="text-sm text-muted-foreground">
              Automated salary-based DeFi investment platform for the modern
              investor.
            </p>
          </div>

          <div className="space-y-4">
            <h4 className="font-semibold">Product</h4>
            <div className="space-y-2">
              <Link
                href="/dashboard"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Dashboard
              </Link>
              <Link
                href="/plans"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Investment Plans
              </Link>
              <Link
                href="/portfolio"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Portfolio
              </Link>
            </div>
          </div>

          <div className="space-y-4">
            <h4 className="font-semibold">Resources</h4>
            <div className="space-y-2">
              <Link
                href="/docs"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Documentation
              </Link>
              <Link
                href="/api"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                API Reference
              </Link>
              <Link
                href="/support"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Support
              </Link>
            </div>
          </div>

          <div className="space-y-4">
            <h4 className="font-semibold">Company</h4>
            <div className="space-y-2">
              <Link
                href="/about"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                About Us
              </Link>
              <Link
                href="/privacy"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Privacy Policy
              </Link>
              <Link
                href="/terms"
                className="block text-sm text-muted-foreground hover:text-foreground"
              >
                Terms of Service
              </Link>
            </div>
          </div>
        </div>

        <div className="border-t border-border mt-8 pt-8 text-center">
          <p className="text-sm text-muted-foreground">
            © 2025 DIP. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
