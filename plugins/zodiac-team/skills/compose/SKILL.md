---
name: compose
description: Compose an agent team from zodiac developer personas - select the right subset for any task
---

# Zodiac Team Composer

## Overview

Select the right subset of zodiac developer personas for a given task. Uses element/modality balance, natural pairings, and task-specific reasoning to recommend a team.

## When to Use

Use when:
- Composing an agent team for a task and want persona-driven role diversity
- User says "build me a team for X", "which personas should I use?"
- Starting a multi-agent workflow that needs balanced perspectives

## The 12 Personas

### Fire Signs — Action-oriented, initiative-driven

| Sign | Archetype | Modality | One-liner |
|------|-----------|----------|-----------|
| Aries | The Launcher | Cardinal | Breaks through blockers, writes first drafts, ships MVPs |
| Leo | The Tech Lead | Fixed | Drives quality through craft pride, owns critical modules |
| Sagittarius | The Explorer | Mutable | Evaluates new tech, spikes solutions, sees the big picture |

### Earth Signs — Detail-oriented, quality-focused

| Sign | Archetype | Modality | One-liner |
|------|-----------|----------|-----------|
| Taurus | The Reliability Engineer | Fixed | Builds things that don't break, operational excellence |
| Virgo | The Code Analyst | Mutable | Finds the bug everyone missed, code review rigor |
| Capricorn | The Program Architect | Cardinal | Sets standards, defines process, long-term planning |

### Air Signs — Ideas-oriented, systems thinkers

| Sign | Archetype | Modality | One-liner |
|------|-----------|----------|-----------|
| Gemini | The Polyglot | Mutable | Connects disparate systems, translates between teams |
| Libra | The API Designer | Cardinal | Clean interfaces, fair tradeoffs, consensus building |
| Aquarius | The Systems Architect | Fixed | Novel architectures, first-principles thinking |

### Water Signs — People-oriented, intuition-driven

| Sign | Archetype | Modality | One-liner |
|------|-----------|----------|-----------|
| Cancer | The Team Anchor | Cardinal | Onboarding, documentation, psychological safety |
| Scorpio | The Debugger | Fixed | Root cause analysis, won't quit until found |
| Pisces | The UX Empath | Mutable | Sees what users actually need vs. what was specified |

## Balance Rules

### Element Balance

A well-rounded team covers at least 3 of 4 elements:

| Missing Element | Consequence |
|----------------|-------------|
| No Fire | Team stalls, nothing ships |
| No Earth | Team ships bugs, quality suffers |
| No Air | Wrong abstraction, lacks coherence |
| No Water | Misses user needs, ignores hidden risks |

### Modality Balance

| Modality | Role | When Needed |
|----------|------|-------------|
| Cardinal | Initiators — start things, set direction | Early in project or when stuck |
| Fixed | Sustainers — see things through, hold the line | During execution and maintenance |
| Mutable | Adapters — refine, iterate, respond to feedback | During iteration and feedback cycles |

Anti-patterns: All Cardinals start everything, finish nothing. All Fixed resist change. All Mutable pivot endlessly.

## Pairings

### Natural Pairings (complementary strengths)

- **Aries + Virgo** — launcher writes the first pass, analyst hardens it
- **Leo + Scorpio** — tech lead drives quality, debugger verifies it
- **Sagittarius + Taurus** — explorer finds the approach, reliability engineer makes it production-ready
- **Gemini + Capricorn** — polyglot connects the pieces, program architect keeps them structured
- **Libra + Aries** — API designer shapes the contract, launcher moves past analysis paralysis
- **Aquarius + Cancer** — systems architect designs the vision, team anchor makes it accessible
- **Pisces + Capricorn** — UX empath identifies user needs, program architect scopes them into a plan

### Tension Pairings (productive friction)

- **Aries vs Taurus** — speed vs safety
- **Scorpio vs Sagittarius** — depth vs breadth
- **Aquarius vs Virgo** — abstraction vs detail

## Team Templates

| Size | Name | Signs | Use Case |
|------|------|-------|----------|
| 3 | **Strike Team** | Aries + Virgo + Scorpio | Fast, high-quality execution with deep verification |
| 3 | **Design Panel** | Libra + Aquarius + Pisces | Architecture decisions with user empathy |
| 4 | **Review Board** | Virgo + Scorpio + Libra + Taurus | Thorough code/design review with multiple lenses |
| 4 | **Build Squad** | Aries + Gemini + Virgo + Cancer | Ship features with cross-cutting concerns covered |
| 5 | **Full Spectrum** | Aries + Virgo + Aquarius + Scorpio + Cancer | One per cognitive style plus team cohesion |

## Workflow

When composing a team:

1. **Understand the task** — What type of work? (dev, review, decision, brainstorm)
2. **Determine team size** — How many agents does the task warrant? (typically 3-5)
3. **Check templates** — Does a preset template fit the task?
4. **If no template fits**, compose manually:
   a. Pick the primary persona for the core task
   b. Add a complementary persona (natural pairing)
   c. Check element balance — are at least 3 elements covered?
   d. Check modality balance — is there at least one Cardinal, one Fixed, one Mutable?
   e. Add a tension pairing if the task benefits from productive friction
5. **Present the team** — List each persona with their role in this specific task
6. **Invoke personas** — User invokes individual `/zodiac-<sign>` skills for each team member

## Examples

**User:** "I need a team to review a critical security patch"
**Team:** Scorpio (deep security investigation) + Virgo (code correctness) + Taurus (operational safety) + Libra (API impact)
**Reasoning:** Water + Earth + Earth + Air covers 3 elements. Fixed + Mutable + Fixed + Cardinal covers 3 modalities. Security-heavy task needs Scorpio's depth and Taurus's reliability focus.

**User:** "I need a team to brainstorm a new feature"
**Team:** Sagittarius (exploration) + Aquarius (novel approaches) + Pisces (user needs) + Aries (momentum)
**Reasoning:** Fire + Air + Water + Fire covers 3 elements. Mutable + Fixed + Mutable + Cardinal covers 3 modalities. Creative task needs breadth and user empathy, with Aries to keep momentum.
