---
title: Loop Engineering Explained
aliases: [loop engineering, agent loops, loop-based development]
type: source
domain: ai-agentic
status: seed
tags: [source, agent-loops, agentic, context-engineering, skills, sub-agents]
updated: 2026-06-21
source_url: https://www.youtube.com/watch?v=NjXIIH9vcv0
source_type: transcript
ingested: 2026-06-21
feeds: [agentic-loop, prompt-engineering, context-engineering, agent-orchestration]
---

# Loop Engineering Explained

> [!info] Source metadata
> **Author/Org:** Louis François, CTO & co-founder, Towards AI · **Date:** 2026 · **URL:** https://www.youtube.com/watch?v=NjXIIH9vcv0

## Key takeaways

- **Loop engineering** = designing loops that prompt agents, rather than prompting agents directly; the decision-maker is inside the loop (not fixed like a cron job).
- Every working loop requires two prerequisites: a **trigger** (PR, CI failure, schedule, message) and a **verifiable goal** (deterministic like "all tests pass", or soft like a reviewer model checking a UI spec).
- Addy Osmani's five-part anatomy of a loop: **automations** (self-starting), **work trees** (parallel isolated agents), **skills** (reusable conventions), **plugins/connectors** (tools), **sub-agents** (separation of writer and judge) — plus **memory** because the model forgets.
- **Skills are the most underused lever:** a loop without skills rediscovers your project from zero on every run, burning tokens relearning what you already know. Skills compound.
- Two hard problems: (1) defining a precise, verifiable goal is genuinely difficult for exploratory or creative work; (2) **cost can escalate fast** — unconstrained self-prompting loops can burn millions of tokens overnight.
- Every serious loop needs hard safety rails: max iteration count, no-progress detection, and a token/dollar budget cap; exit condition must be stronger than the agent's own claim of "done".
- Evolution of the leverage point: prompt engineering → context engineering → harnesses → loop engineering. The prompt becomes a component inside a larger repeatable system.
- Practical heuristic: if the task is one-off, just prompt. If it repeats with a clear pass/fail signal, build a loop. If the goal is still vague, define it first.

## Notable claims (with location)

- Peter Steinberger (creator of OpenClaw) and Boris Turney (leads Claude Code at Anthropic) both independently stated they no longer prompt agents — they design loops. (~0:53)
- "If a loop only means run the same prompt every hour, then we already have that. It's called a cron job." — the key distinction is that the agent controls the loop, not a fixed script. (~1:23)
- "A loop with no reusable skills just rediscovers your project from zero every run. It burns token relearning what you already know. A loop with good skills starts to compound." (~3:23)
- Cost warning: "If you let an agent prompt itself continuously, review itself, spawn helpers, and keep retrying, you can burn through millions of tokens quickly, especially if they run when you sleep and can't check." (~4:49)
- "Loop engineering is easiest to hype on Twitter, especially when you work at a place with a huge token budget like Anthropic." (~5:03)

## Feeds these wiki pages

- [[agentic-loop]]
- [[prompt-engineering]]
- [[context-engineering]]
- [[agent-orchestration]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*

## Transcript

If you're coding with Cloud or CodeX
today, there's a new paradigm you're
going to love. It cuts down the number
of steps to the final output by half.
Your current workflow probably looks
like this. You write a prompt, give a
file access to your agents, the agent
edit the files, you accept all
permissions, you run tests, something
breaks, you ask to fix it, sometimes it
works in one go, and sometimes you have
to paste the error back or even take a
screenshot. Then it tries again, and
after 20 minutes, you realize that
you're babysitting the exact process you
wanted to offload. You are focusing on
the dumb work, not the thinking part.
But if agents are already good enough,
why do you have to keep repeating this
process? This new paradigm I mentioned,
called loop engineering, is the idea
that allows you to stop being that
babysitter. No need to micro prompt
them. You can have it work or loop with
itself instead. We moved from prompt
engineering to context engineering to
harnesses, and now loop engineering. And
to be honest, they are all about the
same thing, steering the model as best
as we can, which is only possible
through the context or the prompt that
we give it.
This new one is worth understanding
because it describes a real shift in how
developers use coding agents in 2026.
I'm Louis François, CTO and co-founder
of Towards AI, where we turn developers
into AI engineers who build and ship
production AI systems. And speaking
about loops and what developers should
do, if this kind of practical AI
engineering content helps you, please
consider subscribing to the YouTube
channel. You'll enter a great loop where
you can learn every week with a new
video. We're on the road to hitting
100,000 subscribers this year. So please
help out and consider the small click.
Let's get into it. The term loop
engineering exploded after Peter
Steinberger, the creator of open claw,
posted that you should not be prompting
coding agents anymore.
You should be designing loops that
prompts your agent. And it wasn't just a
one-off hot take. Boris Turney, who
leads cloud code at Anthropic, said the
same thing. He doesn't prompt Claude
anymore.
>> At that point, I was running, you know,
maybe five, 10 quads in parallel, and my
coding was prompting Claude to to write
code. Now, it's actually leveled up, I
think again, to the next level of
abstraction, where I don't prompt Claude
anymore. I have loops that are running.
They're the ones that are prompting
Claude and kind of figuring out what to
do. My job is to write loops.
>> In his own words, his job is to write
loops. When the people building both
Codex and Claude Code land on the same
ID, it might be worth taking it
seriously. The most interesting reply
was basically, "Okay, but what does that
look like in practice?" Because if a
loop only means run the same prompt
every hour, then we already have that.
It's called a cron job. It's older than
many of us. But there's a difference
with loop engineering. Here, the
decision-maker is inside the loop. A
cron job runs a fixed script. A loop
runs an agent that looks at the current
state, choose the next action, does it,
checks the result, and decides what to
do next. It continue, it retries, it
rollbacks, it stops. The agent controls
the loop, and it works because LLMs are
now sufficiently capable of
understanding proper goals and reward
signals.
But for a loop to work at all, it needs
two things before anything else: a
trigger and a verifiable goal.
The trigger is what starts the loop. It
could be a pull request opening, a
failing CI run, a daily schedule, a
Slack message, or manually typing a
comment or a first prompt.
The verifiable goal is what tells the
model it can stop. That can be
deterministic, like all tests have
passed and CI is green, or softer, like
a reviewer model checks whether the UI
matches the spec. Or it can even go with
a list of predefined subjective
criterias, like I do for my scripts and
lessons work. But there has to be some
check. Otherwise, you did not build a
loop, you just built a very confident
token furnace.
Codex already does that automatically
until the task you asked for is done.
But you can also build this yourself
with a loop that leverages these new
models, for example, via an automation
on Cursor. So in the end, prompt
engineering optimizes a single
interaction, but here loop engineering
turns that into a repeatable process
around many interactions. So now the
prompt becomes a component within the
larger system, and it's even more
important.
I like this framing because it matches
what I've been feeling with coding
agents lately. The prompt is rarely the
hard part anymore. You don't struggle
writing a prompt, especially since late
2025. The hard part is everything around
it. What context should the agent see?
What tools should it use? What counts as
done? What happens when it fails, and
how expensive is it allowed to be before
we shut it down?
That's why most of my recent talks and
conferences have been focusing on
compaction and memory. Now that models
are much more intelligent, but also more
expensive, we need to control what they
have access to in order to reduce cost,
reduce latency, improve long
discussions, and improve the results
overall.
It's done by managing context
intelligently.
And finally, we have a term that builds
this process into the system and
integrates it into the same loops to be
viable.
If you're thinking, how is this
different from React that we teach in
our course or agent loops like the Ralph
loop, here's what's new.
Other systems let the LLM run again.
With this approach, the loop becomes a
unit of work. As I said, it can run on a
schedule, it can open work trees, it can
spawn sub agents, it can write a state
to a file or a linear board. It can
survive your laptop closing, which also
means it can survive without you. So, it
should be able to work without you as
well.
But then, that also means it shouldn't
need you to prompt it every single time.
In an amazing Twitter article, Addy
Osmani breaks a loop down into five
pieces plus memory. And I think this is
the clearest practical explanation.
First, automations. So, the loop wakes
up on its own. Or you can start it if
you want. Second, work trees. Here, we
have parallel agents that do not
overwrite each other, especially when
coding. I do this myself with Codex when
I want to take a conversation into two
completely different directions. I just
split it into two work trees and let
each one diverge.
Third, we have skills so that the agent
does not guess your project rules or
even any rule you'd like about you, how
you work, how you talk, etc.
And every time you launch it, it uses
them.
Fourth, we have plugins or connectors.
So, the agent can actually do things,
use tools like GitHub, Linear, Slack, or
your database. Fifth, sub agents. So,
the one writing is not the same as the
one judging.
And then, memory because the model
forgets, but the Ripple doesn't. I have
to emphasize the skills part because
even though it's a bit old now, the vast
majority of people I see still under use
skills. A loop with no reusable skills
just rediscover your project from zero
every run. It burns token relearning
what you already know. A loop with good
skills starts to compound.
The skill is where you write the
convention, the examples, the test
command, the things you never want
repeated. It's just a big list of
markdown files. Make them as dense as
possible, but also as clean and small as
possible. One skill for one task. You
don't want them to fill the context.
Then, ask Codex or whatever agent to
organize them and build an index. This
way, your coding agent will simply have
to use this index to know which skill to
open and which skill it has access to,
so you never have to prompt it again to
open X and Y skill, but just to check
the skill list and use if needed.
Now, back to loops. What does that look
like? A simple version could run every
morning. It reads yesterday's CI
failures, open issues, and recent
commits. It writes a short state file
with what looks worth doing. For one
issue, it opens a separate work tree and
sends one agent to draft a fix. Once
done, another agent reviews it against
your project skills and tests, and if
the tests pass, it opens a PR and
updates the ticket. If the test failed,
it feeds the error back once or twice.
If it gets stuck, it stops and puts the
problem in your inbox. It basically does
what you should have done using cloud
code.
That is loop engineering.
You didn't ask the agent seven times.
You didn't have to prompt it when you
woke up to start working or to then do
the PR this way or that way. You
designed the seven-step system once with
tons of skills that they can use to
replicate how you would have done it or
code it designed it for you, but you
thought about what should be done and
automated it.
This is also the difference between
automation and loops. Automation says to
do step one, then step two, step three,
always the same.
But a loop looks at the state, decide
what to do next, do it, check it, and
decides whether or not another iteration
is needed. It's just much more flexible.
It's basically more like imitating an
engineer rather than running a script.
But this is also where the hype gets
dangerous. Right now, there are two big
problems with loop engineering that you
need to be careful of.
First, defining a good goal for the loop
itself is hard. It needs to be precise,
but also verifiable. Software
development is often exploratory. You
don't always know the final shape of the
feature at the start. And if the end
state is fuzzy, the loop will optimize
toward whatever fake sentence you gave
it. And that can be worse than doing one
careful manual pass. And here coding is
actually the easier task. If you're
trying to automate some more subjective
task or creative task like writing a
YouTube script about loop engineering
and telling it to make it good, it may
just rewrite it indefinitely. And now
that I think about it, that might be
some human trait that some of us have
with
a dozen unfinished scripts, maybe.
So,
does that mean we reached AGI?
Anyways, the reward or just overall goal
is where you need to put a lot of
thought and consideration into and
experiment a lot as well. Now, the
second problem is the most important to
us, cost. It can get ridiculous quite
fast. If you let an agent prompt itself
continuously, review itself, spawn
helpers, and keep retrying, you can burn
through millions of tokens quickly,
especially if they run when you sleep
and can't check.
This is why loop engineering is easiest
to hype on Twitter, especially when you
work at a place with a huge token budget
like Anthropic.
But for the rest of us, the budget is
part of the architecture. I personally
want to manually launch my loops and
check them to ensure everything goes
smoothly. They never run when I sleep.
This is also why every serious loops
need a hard break.
A maximum number of iterations, no
progress detection, and a token or
dollar budget that you can use per day.
And it needs verification that is
stronger than the agent saying it's
done.
Run test, type check, use a reviewer
agent, compare the diff to the spec. I
have the same stance here as I do with
agents in general at Towards AI. Start
simple, then add autonomy only when it
pays for itself, only when you
absolutely need it. If the workflow is
one-off, just prompt the model.
If the work repeats and has a clear pass
or fail signal, or in other words, if
you feel like you only do the dumb
repeatable actions, you can build a
loop. If the task is still somewhat
vague, like think of a better product
strategy, maybe don't hand that to a
loop right now and go make a coffee to
talk to some other humans and first
figure out a better goal, please. So,
the takeaway here is not that prompt
engineering and the other engineering
types are dead.
It's that the leverage point moved. Five
years ago, you wrote code yourself. Two
years ago, you prompted a model to write
the code. Last year, you watched Claude
code for you and just accepted tasks one
by one in case it [  ] up.
And today, for the right tasks, you
design the loop that prompts, checks,
retries, and stops by itself. Whatever
you do, if you do not change your
workflow or go all in with loops, just
make sure that you stay the engineer.
Read what it shipped on the quality,
write the skills, or at least control
them or understand them. Define the stop
conditions, the precise goal, and the
subgoals you need your agent to do.
Because in the end, you can use loops to
either move faster on work you
understand or to avoid understanding the
work at all. Make the right choice for
your future self. And what about you?
Are you already using loops? I'd love to
know your current agent setup. Please
let me know in the comments. I hope
you've enjoyed this video. If you do,
please consider subscribing. Thank you
for watching until the end, and I'll see
you in the next one with another very
interesting, timely topic involving
China. I won't say more.
