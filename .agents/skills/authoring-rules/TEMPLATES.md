# Universal Rule Templates

## 1. The "Tech Stack & Style" Base
*Best for the main project-wide rule file. Usually set to always apply.*

```markdown
---
description: General coding standards, tech stack definitions, and behavioral guidelines.
globs: *
alwaysApply: true
---

# Tech Stack
- Framework: [e.g., React 18]
- Language: [e.g., TypeScript 5.x]
- Styling: [e.g., Tailwind CSS]

# Coding Style
- **Functional**: Prefer functional components over classes.
- **Naming**: Use `camelCase` for functions, `PascalCase` for components.
- **Typing**: Strict TypeScript. No `any`. Use `interface` over `type`.

# Behavior
- Be concise.
- When fixing bugs, explain the root cause briefly before the fix.

```

## 2. The "Pattern Enforcement" Rule

*Best for specific tasks that shouldn't clutter the global context.*

```markdown
---
description: Standards for writing SQL migrations and schema updates.
globs: supabase/migrations/*.sql
alwaysApply: false
---

# Database Migration Standards

## Context
Apply this whenever writing SQL migrations or updating the schema.

## Rules
1. Never alter a column type directly; create a new column, backfill, then drop.
2. Always add a `DOWN` migration for rollbacks.
3. Index all foreign keys.

## Example (Good)
```sql
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
CREATE INDEX idx_users_status ON users(status);

```

```

## 3. The "Chain of Thought" Trigger
*Best for complex architectural tasks.*

```markdown
---
description: Planning protocol for complex architectural changes or major refactors.
globs: 
alwaysApply: false
---

# Architecture Planning

Before writing any code for complex features:
1. **Analyze**: List the files that will be touched.
2. **Plan**: Write a 3-step plan in pseudocode.
3. **Confirm**: Ask the user for confirmation before executing.

```

## 4. The "Domain-Specific" Rule

*Best for enforcing project-specific patterns in specific file types.*

```markdown
---
description: Standards for API response handling and typing.
globs: src/api/**/*.ts
alwaysApply: false
---

# API Response Handling

## Pattern
All API responses must be wrapped in a Result type:

```typescript
type Result<T> = { ok: true; data: T } | { ok: false; error: string };

```

## Example

```typescript
// Good
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.users.findById(id);
    return { ok: true, data: user };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

```

```
