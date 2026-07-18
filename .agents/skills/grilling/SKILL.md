---
name: grilling
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
author: Matt Pocock
version: 1.0.0
groups:
  - planning
---

# When To Use

Use when further context, feedback, or decisions need to be made by the user before proceeding.

# Pipeline

## 1. Assess the Context

Ask yourself: do we possess the necessary context to even formulate the correct questions? 
- Check the injected context or design. 
- If the context is sufficient, proceed to Step 2. 
- If not, you must find it first. Gather the missing context by exploring the codebase or asking the user preliminary fact-finding questions.

## 2. Plan the Interview Sequence

Once you have the baseline context, break down the missing information into a decision tree of dependent choices. Plan exactly WHAT questions need to be asked and in WHAT order to resolve all dependencies logically.

## 3. Interview the User

Walk down each branch of your planned decision tree, resolving dependencies one by one.

- **Look up facts:** If a piece of information can be found by exploring the codebase, look it up rather than asking the user.
- **Ask for decisions:** The decisions are the user's. Put each decision to them clearly.
- **Provide recommendations:** For each question asked, provide your recommended answer or default path.
- **One at a time:** Ask questions strictly one at a time. Wait for user feedback on each question before continuing. Asking multiple questions at once is bewildering.

## 4. Confirm Shared Understanding

Continue the interview relentlessly until reaching a shared understanding of every aspect of the plan or context. Once all branches are resolved, summarize the agreed-upon decisions. Do not enact or execute the plan until the user confirms.
