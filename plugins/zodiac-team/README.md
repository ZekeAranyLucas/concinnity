# zodiac-team

Multi-agent code review with developer personas.

Dispatches a team of zodiac-archetype agents to review code, debate issues, and compose artifacts. Reviews are prioritized using Concinnity — a rubric that ranks issues by their impact on code cohesion, correctness, and maintainability.

## Install

```
/plugin marketplace add ZekeAranyLucas/concinnity
/plugin install zodiac-team@concinnity
```

Then run `/reload-plugins`.

Reviews work standalone — findings save to `.issues/` and appear in chat. If [`dot-issues`](https://github.com/ZekeAranyLucas/concinnity/tree/main/plugins/dot-issues) is also installed, the closing recommendations adapt to offer triage (`/dot-issues-triage`) and auto-fix (`/dot-issues-fix`) workflows.

## Skills

| Skill | Description |
|-------|-------------|
| `zodiac-team-review` | Dispatches a panel of zodiac agents to review a PR or file set |
| `zodiac-team-debate` | Runs an adversarial debate between agents on a contested design question |
| `zodiac-team-compose` | Assembles a multi-agent team to collaboratively produce a document or plan |
| `prioritize-issues-by-concinnity` | Ranks a list of issues by Concinnity score (cohesion, correctness, maintainability) |

## Agents

These agents are dispatched by team skills. They are not intended to be invoked directly.

| Agent | Archetype | Element + Modality |
|-------|-----------|--------------------|
| `zodiac-aries` | The Pioneer | Fire, Cardinal |
| `zodiac-taurus` | The Craftsperson | Earth, Fixed |
| `zodiac-gemini` | The Connector | Air, Mutable |
| `zodiac-cancer` | The Caretaker | Water, Cardinal |
| `zodiac-leo` | The Performer | Fire, Fixed |
| `zodiac-virgo` | The Analyst | Earth, Mutable |
| `zodiac-libra` | The Diplomat | Air, Cardinal |
| `zodiac-scorpio` | The Investigator | Water, Fixed |
| `zodiac-sagittarius` | The Visionary | Fire, Mutable |
| `zodiac-capricorn` | The Strategist | Earth, Cardinal |
| `zodiac-aquarius` | The Innovator | Air, Fixed |
| `zodiac-pisces` | The Synthesizer | Water, Mutable |
