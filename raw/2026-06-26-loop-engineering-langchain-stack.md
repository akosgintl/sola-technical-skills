---
title: "The Art of Loop Engineering (LangChain)"
aliases: [loop stacking, four-loop stack, loopcraft, stacking loops]
type: source
domain: ai-agentic
status: seed
tags: [source, agent-loops, loop-engineering, verification, hill-climbing, langchain, langsmith]
updated: 2026-06-26
source_url: https://www.langchain.com/blog/the-art-of-loop-engineering
source_type: article
ingested: 2026-06-26
feeds: [agentic-loop]
---

# The Art of Loop Engineering (LangChain)

> [!info] Source metadata
> **Author/Org:** Sydney Runkle (LangChain) · **Date:** 2026-06-16 · **URL:** https://www.langchain.com/blog/the-art-of-loop-engineering
> Builds on Swyx's "loopcraft: the art of stacking loops" (latent.space).

## Key takeaways

- **Central thesis — stack loops.** "The core agent algorithm is simple: give the LLM context and let it call tools in a loop until it's done." But that is only the *innermost* loop. Effective agents come from **stacking loops** (the term "loopcraft" is Swyx's). Four nested levels, each wrapping the one below:
- **Loop 1 — Agent loop:** a model calls tools in a loop until the task is complete. Impact: *automate work*. (LangChain `create_agent` + any model + tools.)
- **Loop 2 — Verification loop:** wrap the agent with a **grader** that checks output against a rubric and, on failure, sends it back with feedback to retry. Graders are deterministic *or* agentic (LLM-as-judge). Impact: *ensure quality/correctness*. Trade-off: adds latency and cost per run — worth it when quality > speed (most production cases). (`RubricMiddleware` / `after_agent` hook.)
- **Loop 3 — Event-driven loop:** an event (new document, schedule, webhook) fires the agent, so it runs continuously in the background rather than being manually invoked. Impact: *automated work at scale*. (LangSmith Deployment with cron/webhooks, or Fleet channels; OpenClaw "heartbeats" are a popular example.)
- **Loop 4 — Hill-climbing loop:** the most important one — it automates *improvement*, not work. Production traces feed an analysis agent that **rewrites the harness config** (prompts, tools, grader tweaks). "The return arrow doesn't just loop back to the top — it reaches inside and updates the agent loop directly." Each outer cycle makes the inner loops more effective. (LangSmith Engine.) Can also feed RL fine-tuning for open-weight models, or improve memory/retrieved skills.
- **Human oversight at every level** (not removed by automation): (1) require human input before sensitive tool calls in the agent loop; (2) human-as-grader in the verification loop; (3) human approves outputs in the application loop; (4) harness improvements flow through human review before deployment. HITL is a first-class primitive in LangChain.
- **Where value compounds:** loops 1–2 are well understood; the frontier is loops 3–4, "where value compounds by embedding agents into your ecosystem that continuously improve in response to your criteria."

## Notable claims (with location)

- Worked example throughout: an internal **docs-writing agent** — loop 1 drafts doc changes and opens a PR; loop 2 runs tests/link-checks/diff-scope checks; loop 3 fires it from a `#docs-plz` Slack channel via Fleet; loop 4 runs Engine over its traces to file issues against offending prompts/tools.
- "AI leaders like Steipete, Boris, and Andrej have all arrived at the same conclusion: the potential in agents is in the loops you build around them."
- Satya Nadella's framing (quoted): "companies that build learning loops early, where human judgment and token capital compound together, will build an advantage that's hard to replicate."

## Feeds these wiki pages

- [[agentic-loop]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*

## Article (full text)

# The Art of Loop Engineering

Sydney Runkle — June 16, 2026 (7 min)

Agents are useful because they help us automate work by taking actions in the real world. But getting agents to do valuable work reliably takes more than just a good model: it requires a carefully designed harness that's fit to a set of tasks.

The core agent algorithm is simple: give the LLM context and let it call tools in a loop until it's done. This is the most fundamental loop. But it's far from the only loop that powers agents. Swyx recently wrote a great piece on "loopcraft: the art of stacking loops", the idea that you can stack and extend loops to build more effective agents.

Here's how we think about that stack, and how to instrument each level with LangChain primitives.

## Loop 1: The Agent

At its core, an agent is just a model calling tools in a loop until a task is complete.

This is what LangChain's `create_agent` gives you. Pick any model, plug in tools, and you have a working agent loop. Tools are what give the agent the power to take action in the real world.

Take our internal docs agent as an example (which we'll use as a motivating example for the rest of this blog). At the first loop level, it receives a request for a documentation improvement, the model plans and draft changes, and it uses tools to clone repos, read files, write docs, open a pull request, etc.

## Level 2: Verification loop

The agent loop gets work done, but it doesn't always produce correct or consistent work on the first pass. When consistency matters, it's often useful to wrap it in a verification loop that checks the output and sends feedback back to the model when it falls short.

The verification loop adds a grader: something that checks the agent's output against a rubric and, if it fails, sends the result back with feedback. Graders can either be deterministic or agentic (LLM as a judge is a classic example, here).

`RubricMiddleware` handles this pattern, or you can wire it up with an `after_agent` hook on `create_agent`.

For our docs writer example, the grader runs tests after each attempt, checking that all links resolve, all CI checks pass, and the diff is scoped to what was actually requested. No manual review needed to catch those classes of error.

One tradeoff: adding verification increases latency and cost per run. It's worth it when quality matters more than speed, which is most production use cases.

## Level 3: Event driven loop

One of the most important parts of agent development is the integrations layer: connecting your agent to your ecosystem so that it can run in the background.

The event-driven loop connects your agent to your ecosystem. An event fires — a new document lands, a schedule triggers, a webhook arrives — and the agent runs. The agent isn't something you invoke manually; it's a component running continuously inside a larger system.

LangSmith Deployment supports the trigger infrastructure, including support for cron schedules and webhooks. One popular example of crons in action is "heartbeats" in openclaw, which turn your agent into an always-on, proactive assistant.

Our docs agent is powered by Fleet, our no-code agent builder. Fleet's channels and schedules handle event-driven and cron-style triggers. We use a channel to fire off the docs agent whenever a message is sent in our `#docs-plz` Slack channel.

## Level 4: Hill climbing loop

The first three loops automate work. The fourth (and arguably most important) automates improvement!

Every agent run produces a trace: a record of what the model did, the tools it called, grader feedback, etc. Those traces contain high value signal regarding what's working and what isn't. The hill climbing loop runs an analysis agent over those traces and uses the findings to rewrite the harness with improved configuration. That can include prompt/tool tweaks or grader tweaks.

In LangSmith, you can use Engine, our trace analysis agent, to instrument this fourth loop.

Wrapping up the docs agent analogy, we run engine over the docs agent traces to detect any issues. When multiple traces signal a potential problem, an issue is filed requesting changes to the offending prompt or tool.

The key move here is that the return arrow doesn't just loop back to the top — it reaches inside and updates the agent loop directly. Each cycle of the outer loop makes the inner loops more effective.

**Looking forward:** prompt and tool configuration are the most simple things to improve, but they're not the only options. For teams running open-weight models, the hill climbing loop can feed into RL fine-tuning, using trace or eval outcomes as training signal to improve the model itself. Auxiliary context like memory and retrieved skills can be improved the same way. The loop is the pattern; what it optimizes is up to you.

## Human oversight and expertise

Automation doesn't mean removing humans from the loop. At every level, there are natural points where human oversight adds value. An automated grader can check whether links resolve; it takes a human to notice the framing is wrong for the audience. That kind of judgment, earned from context, experience, and taste, is exactly where human review earns its place.

Some expertise should be codified in the prompt/tools themselves, but for sensitive actions, live human review is essential (think financial transactions, DB operations, etc). LangChain makes it straightforward to instrument these touch points in every loop:

1. In the agent loop, require human input before sensitive actions/tool calls
2. In the verification loop, a human can act as the grader for sensitive workflows
3. In the application loop, a human can approve outputs before they're returned to the end user
4. In the hill climbing loop, harness improvements can flow through human review before deployment

All of LangChain's open source frameworks make adding a "human in the loop" a first class primitive.

## Putting it all together

| Loop | What it does | Impact | LangChain primitive |
| --- | --- | --- | --- |
| 1. Agent loop | Model calls tools repeatedly until a task is complete | Automate work | create_agent, any LangChain-supported model |
| 2. Verification loop | Agent runs, output is scored against a rubric, retried with feedback if it fails | Ensure work quality and correctness | RubricMiddleware |
| 3. Event driven loop | Events trigger agent runs that update a real system | Automated work at scale | LangSmith Deployment with cron triggers / webhooks or Fleet channels |
| 4. Hill climbing loop | Traces from production runs feed an analysis agent that improves the harness config | Harness improvements | LangSmith Engine |

This is what loop engineering — or loopcraft, as swyx puts it — actually looks like in practice. AI leaders like Steipete, Boris, and Andrej have all arrived at the same conclusion: the potential in agents is in the loops you build around them.

We've been thinking about loops 1 and 2 for a while. But focus should pivot to loops 3 and 4 where value compounds by embedding agents into your ecosystem that continuously improve in response to your criteria.

Satya frames the organizational stakes: companies that build learning loops early, where human judgment and token capital compound together, will build an advantage that's hard to replicate.
