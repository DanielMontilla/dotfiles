---
name: finding-skills
description: Discovers and surfaces available skills matching user requests. Use when the user asks "what skills do you have", "how do I do X", or wants to find a skill for a specific task.
author: Daniel Montilla
version: 1.0.1
license: MIT
dependencies:
  - executing-skills
groups:
  - skills
---

# When To Use

Use when the user asks "what skills do you have", "how do I do X", or wants to find a skill for a specific task.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Detect Trigger

User asks about capabilities, how to do something, or what skills exist.

## 2. Search Skills

Scan `.agents/skills/*/SKILL.md` for matching descriptions using Glob and Grep. Search for keywords matching user intent.

## 3. Match Intent to Skill

Compare user request against each skill's `name` and `description`. Present matches with a brief summary of each.

## 4. Handle No Match

If no skill matches, suggest creating a new one using `authoring-skills`.

# Reference

- See [available skills list](../) for all installed skills
