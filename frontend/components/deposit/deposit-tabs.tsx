"use client"

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { SalarySetup } from "./salary-setup"
import { ManualDeposit } from "./manual-deposit"
import { PaymentMethods } from "./payment-methods"

export function DepositTabs() {
  return (
    <Tabs defaultValue="salary" className="w-full">
      <TabsList className="grid w-full grid-cols-3">
        <TabsTrigger value="salary">Salary Setup</TabsTrigger>
        <TabsTrigger value="manual">Manual Deposit</TabsTrigger>
        <TabsTrigger value="methods">Payment Methods</TabsTrigger>
      </TabsList>

      <TabsContent value="salary" className="space-y-6">
        <SalarySetup />
      </TabsContent>

      <TabsContent value="manual" className="space-y-6">
        <ManualDeposit />
      </TabsContent>

      <TabsContent value="methods" className="space-y-6">
        <PaymentMethods />
      </TabsContent>
    </Tabs>
  )
}
