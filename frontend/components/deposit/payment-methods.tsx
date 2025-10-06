"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Wallet, Building, CreditCard, Plus, Settings, Trash2 } from "lucide-react"

const connectedMethods = [
  {
    id: "1",
    type: "wallet",
    name: "MetaMask Wallet",
    details: "0x1234...5678",
    status: "Connected",
    isDefault: true,
  },
  {
    id: "2",
    type: "bank",
    name: "Chase Bank",
    details: "****1234",
    status: "Verified",
    isDefault: false,
  },
  {
    id: "3",
    type: "card",
    name: "Visa Debit",
    details: "****5678",
    status: "Active",
    isDefault: false,
  },
]

function getMethodIcon(type: string) {
  switch (type) {
    case "wallet":
      return <Wallet className="w-5 h-5" />
    case "bank":
      return <Building className="w-5 h-5" />
    case "card":
      return <CreditCard className="w-5 h-5" />
    default:
      return <Wallet className="w-5 h-5" />
  }
}

export function PaymentMethods() {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Connected Payment Methods</CardTitle>
            <Button size="sm">
              <Plus className="w-4 h-4 mr-2" />
              Add Method
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {connectedMethods.map((method) => (
              <div key={method.id} className="flex items-center justify-between p-4 border rounded-lg">
                <div className="flex items-center space-x-4">
                  <div className="p-2 bg-muted rounded-lg">{getMethodIcon(method.type)}</div>
                  <div>
                    <div className="font-medium">{method.name}</div>
                    <div className="text-sm text-muted-foreground">{method.details}</div>
                  </div>
                </div>

                <div className="flex items-center space-x-3">
                  {method.isDefault && <Badge variant="default">Default</Badge>}
                  <Badge variant="secondary">{method.status}</Badge>
                  <div className="flex space-x-1">
                    <Button size="sm" variant="ghost">
                      <Settings className="w-4 h-4" />
                    </Button>
                    <Button size="sm" variant="ghost">
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Payroll Integration</CardTitle>
          <p className="text-muted-foreground">
            Connect with your employer's payroll system for automatic salary deductions
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 border rounded-lg">
              <div className="flex items-center space-x-3 mb-3">
                <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                  <span className="text-blue-600 font-bold text-sm">ADP</span>
                </div>
                <div>
                  <div className="font-medium">ADP Payroll</div>
                  <div className="text-sm text-muted-foreground">Most popular</div>
                </div>
              </div>
              <Button variant="outline" className="w-full bg-transparent">
                Connect ADP
              </Button>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center space-x-3 mb-3">
                <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                  <span className="text-green-600 font-bold text-sm">GP</span>
                </div>
                <div>
                  <div className="font-medium">Gusto Payroll</div>
                  <div className="text-sm text-muted-foreground">Small business</div>
                </div>
              </div>
              <Button variant="outline" className="w-full bg-transparent">
                Connect Gusto
              </Button>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center space-x-3 mb-3">
                <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                  <span className="text-purple-600 font-bold text-sm">PY</span>
                </div>
                <div>
                  <div className="font-medium">Paychex</div>
                  <div className="text-sm text-muted-foreground">Enterprise</div>
                </div>
              </div>
              <Button variant="outline" className="w-full bg-transparent">
                Connect Paychex
              </Button>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center space-x-3 mb-3">
                <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
                  <Plus className="w-4 h-4 text-gray-600" />
                </div>
                <div>
                  <div className="font-medium">Other Provider</div>
                  <div className="text-sm text-muted-foreground">Custom integration</div>
                </div>
              </div>
              <Button variant="outline" className="w-full bg-transparent">
                Request Integration
              </Button>
            </div>
          </div>

          <div className="bg-blue-50 p-4 rounded-lg">
            <h4 className="font-medium text-blue-900 mb-2">How Payroll Integration Works</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• Secure connection to your employer's payroll system</li>
              <li>• Automatic deduction of your chosen investment amount</li>
              <li>• Funds are invested according to your selected plan</li>
              <li>• Full transparency with detailed transaction records</li>
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
