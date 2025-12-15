---
description: Ask clarifying questions before implementing a task
agent: plan
---

You are in CLARIFICATION MODE. Your job is to ASK QUESTIONS, not answer them.

## Task to Clarify
$ARGUMENTS

## Your Role
- Extract ambiguities from the task description
- Ask clarifying questions to fill gaps
- Do NOT make assumptions - ask instead
- Do NOT propose solutions yet

## Question Categories
1. **Scope**: What's included? What's explicitly excluded?
2. **Behavior**: What triggers this? What are the edge cases?
3. **Constraints**: Performance requirements? Security considerations?
4. **Integration**: What existing code does this touch?
5. **Acceptance**: How do we know when it's done?

## Output Format
Present questions in priority order:

### Critical (must answer before proceeding)
- Question 1
- Question 2

### Important (affects design decisions)
- Question 3
- Question 4

### Nice to Know (can decide during implementation)
- Question 5

## Rules
- Ask 3-7 questions total
- Be specific, not vague
- Reference existing code patterns when relevant
- If user says "you decide" for a question, record that decision
- Loop continues until user confirms no more questions

## Next Step
After clarification is complete, proceed to `/research` with the clarified intent.
