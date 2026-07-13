---
name: executing-skills
description: Loads, executes, and verifies skills from .agents/skills/. Use when the user's request matches an existing skill's description or when instructed to use a specific skill.
author: Daniel Montilla
version: 1.0.0
license: MIT
groups:
  - skills
dependencies:
  - finding-skills
---

# When To Use

Use when the user's request matches an existing skill's description, when told to use a specific skill, or when a skill already exists for the task at hand.

# Pipeline

## 1. Identify the Skill

Match the user's request to a skill description. Search `.agents/skills/` using Glob/Grep or load [finding-skills](../finding-skills/SKILL.md) to discover relevant skills.

If no skill matches, stop — do not proceed. Inform the user that no skill exists for their request.

If multiple skills match, select the most specific one. When unsure, ask the user.

## 2. Load the Skill

Use the `skill` tool to load the matched skill:

```
skill name: <skill-name>
```

Read the full skill content, including any linked files in its Reference section.

## 3. Review Prerequisites

Check if the skill has a Prerequisites section. If prerequisites are not met, resolve them before continuing. Do not skip prerequisites.

## 4. Execute the Pipeline

Follow the skill's Pipeline section step by step. Complete each step fully before moving to the next.

## 5. Verify All Skills Were Executed

Before finishing, confirm that every skill loaded during step 2 was actually executed end-to-end. If any skill was loaded but not fully followed, go back and complete it.

This is a lightweight self-check — no formal gates file needed.

## 6. Report

Summarize what was done: which skill was used, what steps were executed, and whether all skills were fully completed.

# Reference

- **Skill discovery**: [finding-skills](../finding-skills/SKILL.md)
- **Skill authoring**: [authoring-skills](../authoring-skills/SKILL.md)
- **Agent Skills spec**: https://agentskills.io
