---
name: interview-drill
description: Run a short technical interview drill in English about decisions made in this codebase. Use at milestone boundaries or when Alejandro asks to practise.
---

# Interview drill

A short, English-only rehearsal of the conversation Alejandro will have about
this project. Delegate to the `english-tech-coach` agent, which holds the
coaching rules; this skill defines the shape of a session.

## Shape of a session

**Two or three questions. Never more.** A drill that feels like an exam gets
avoided, and avoidance costs more than any single session gains.

1. **Open in English and stay there.** No Spanish scaffolding unless he is
   genuinely stuck — then give options to choose from, never "please rephrase".
2. **Ask about this codebase**, never generic trivia. He will be asked about
   his own project; that is what to rehearse.
3. **Follow up once**, the way a real interviewer does: "What would you do if
   the dataset were a hundred times larger?"
4. **Then feedback** — content, phrasing, and one thing to change next time.

## Choosing questions

Pull from decisions actually made in the milestone just completed. Favour
judgement over recall: "why", "what would change if", "what did that cost you".

Milestone-appropriate examples:

| Milestone | Question |
| --- | --- |
| 1 — Docker | *"Why does the API wait for a healthy database instead of just retrying the connection?"* |
| 2 — Auth | *"Your tokens are stateless. How would you revoke one before it expires?"* |
| 3 — Analytics | *"Walk me through why this endpoint uses Dapper instead of EF Core."* |
| 4 — Board | *"The board updates optimistically. What does the user see when the request fails?"* |
| 5 — Deploy | *"Your API sleeps on the free tier. How did you handle that, and what would you do differently with a budget?"* |

## Grading his answer

Judge the **technical answer first**, and say plainly if it is wrong — a drill
that praises a wrong answer is worse than no drill.

Then the phrasing: give the same answer as a fluent engineer would say it, out
loud, in one or two sentences. He is training for a spoken conversation, so the
model answer should sound spoken rather than written.

End with one specific thing to carry into next time. Only one.

## What this is for

The goal is fluency under pressure, not vocabulary breadth. A correct answer
delivered haltingly still loses interviews; a confident, well-structured answer
about a real trade-off wins them. Optimise for the second.
