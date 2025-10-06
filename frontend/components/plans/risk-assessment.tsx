"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { useState } from "react"

const questions = [
  {
    id: "experience",
    question: "What is your experience with DeFi investments?",
    options: [
      { value: "beginner", label: "Beginner - New to DeFi", score: 1 },
      { value: "intermediate", label: "Intermediate - Some experience", score: 2 },
      { value: "advanced", label: "Advanced - Very experienced", score: 3 },
    ],
  },
  {
    id: "timeline",
    question: "What is your investment timeline?",
    options: [
      { value: "short", label: "Less than 1 year", score: 1 },
      { value: "medium", label: "1-5 years", score: 2 },
      { value: "long", label: "More than 5 years", score: 3 },
    ],
  },
  {
    id: "volatility",
    question: "How comfortable are you with portfolio volatility?",
    options: [
      { value: "low", label: "I prefer stable, predictable returns", score: 1 },
      { value: "medium", label: "I can handle moderate fluctuations", score: 2 },
      { value: "high", label: "I'm comfortable with high volatility for higher returns", score: 3 },
    ],
  },
  {
    id: "loss",
    question: "What's the maximum loss you could tolerate in a year?",
    options: [
      { value: "conservative", label: "Less than 5%", score: 1 },
      { value: "moderate", label: "5-15%", score: 2 },
      { value: "aggressive", label: "More than 15%", score: 3 },
    ],
  },
]

interface RiskAssessmentProps {
  onComplete: (riskProfile: "Conservative" | "Balanced" | "Aggressive") => void
  onSkip: () => void
}

export function RiskAssessment({ onComplete, onSkip }: RiskAssessmentProps) {
  const [answers, setAnswers] = useState<Record<string, string>>({})

  const handleSubmit = () => {
    const totalScore = Object.values(answers).reduce((sum, answer) => {
      const question = questions.find((q) => q.options.some((opt) => opt.value === answer))
      const option = question?.options.find((opt) => opt.value === answer)
      return sum + (option?.score || 0)
    }, 0)

    const maxScore = questions.length * 3
    const scorePercentage = totalScore / maxScore

    let riskProfile: "Conservative" | "Balanced" | "Aggressive"
    if (scorePercentage <= 0.4) {
      riskProfile = "Conservative"
    } else if (scorePercentage <= 0.7) {
      riskProfile = "Balanced"
    } else {
      riskProfile = "Aggressive"
    }

    onComplete(riskProfile)
  }

  const isComplete = Object.keys(answers).length === questions.length

  return (
    <Card>
      <CardHeader>
        <CardTitle>Risk Assessment</CardTitle>
        <p className="text-muted-foreground">
          Answer a few questions to help us recommend the best investment plan for you.
        </p>
      </CardHeader>
      <CardContent className="space-y-6">
        {questions.map((question, index) => (
          <div key={question.id} className="space-y-3">
            <h4 className="font-medium">
              {index + 1}. {question.question}
            </h4>
            <RadioGroup
              value={answers[question.id] || ""}
              onValueChange={(value) => setAnswers((prev) => ({ ...prev, [question.id]: value }))}
            >
              {question.options.map((option) => (
                <div key={option.value} className="flex items-center space-x-2">
                  <RadioGroupItem value={option.value} id={`${question.id}-${option.value}`} />
                  <Label htmlFor={`${question.id}-${option.value}`} className="text-sm">
                    {option.label}
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>
        ))}

        <div className="flex space-x-4 pt-4">
          <Button onClick={handleSubmit} disabled={!isComplete} className="flex-1">
            Get Recommendation
          </Button>
          <Button variant="outline" onClick={onSkip} className="flex-1 bg-transparent">
            Skip Assessment
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
