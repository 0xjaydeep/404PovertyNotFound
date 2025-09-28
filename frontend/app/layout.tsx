import type React from "react";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { WalletProvider } from "@/components/wallet/wallet-provider";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { sepolia } from "wagmi/chains";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "DIP - Automated Salary-Based DeFi Investment Platform",
  description:
    "Streamline your wealth building with automated salary deductions invested in Real World Assets through our institutional-grade DeFi platform.",
  generator: "v0.app",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <WalletProvider>
          <RainbowKitProvider initialChain={sepolia}>
            {children}
          </RainbowKitProvider>
        </WalletProvider>
      </body>
    </html>
  );
}
