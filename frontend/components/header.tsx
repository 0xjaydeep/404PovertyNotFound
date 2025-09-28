import Link from "next/link";
import { SimpleWalletButton } from "@/components/wallet/simple-wallet-button";

export function Header() {
  return (
    <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        <div className="flex items-center space-x-8">
          <Link href="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-sm">
                DI
              </span>
            </div>
            <span className="font-semibold text-xl">DIP</span>
          </Link>

          <nav className="hidden md:flex items-center space-x-6">
            <Link
              href="/dashboard"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Dashboard
            </Link>
            <Link
              href="/plans"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Plans
            </Link>
            <Link
              href="/subscriptions"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Subscriptions
            </Link>
            <Link
              href="/portfolio"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Portfolio
            </Link>
            <Link
              href="/deposit"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Deposit
            </Link>
          </nav>
        </div>

        <div className="flex items-center space-x-4">
          <SimpleWalletButton />
        </div>
      </div>
    </header>
  );
}
