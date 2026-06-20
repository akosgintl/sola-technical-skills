---
title: Stop Chasing the Perfect Ontology
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ontology, knowledge-graph, pole-o, graphrag, agent-memory]
updated: 2026-06-20
source_url: https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes
source_type: article
ingested: 2026-06-20
feeds: [agent-memory-architectures, graphrag]
---

# Stop Chasing the Perfect Ontology

> [!info] Source metadata
> **Author/Org:** Paul Iusztin / Decoding AI · **Date:** 2026-05-26 · **URL:** https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes

## Key takeaways

- Designing the "perfect" ontology upfront is the trap that prevents projects from shipping. Start generic, extend through data exploration.
- Real shipped ontologies (Neo4j's create-context-graph catalog — 22 domains) are all 10–12 entity types: a shared 5-noun base + 5–7 domain-specific subtypes.
- POLE+O: Person, Object, Location, Event, Organization — 5 fixed base types, each extensible with subtypes. Exactly like OOP base classes.
- Data-exploration workflow: generic POLE+O → extraction run → inspect clashes → add subtypes → repeat.
- Preferences: things a noun likes/dislikes. Fields: category, preference, context, confidence, embedding. Attached to Person by default.
- Facts: atomic triplets (subject, predicate, object) with bi-temporal validity (valid_from, valid_until). No relationships — retrieved only via semantic/text search. Fallback for anything that doesn't fit a noun or preference.
- Facts let you ship before the ontology is perfect; claims migrate toward typed entities as the schema matures.

## Feeds these wiki pages

- [[agent-memory-architectures]]
- [[graphrag]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*

[![Decoding AI Magazine](https://substackcdn.com/image/fetch/$s_!k2ig!,w_40,h_40,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F00bc74e0-3601-49ce-8ab9-4c7b499ce597_1280x1280.png)](https://www.decodingai.com/)

# [![Decoding AI Magazine](https://substackcdn.com/image/fetch/$s_!XBIw!,e_trim:10:white/e_trim:10:transparent/h_120,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F85e4cd45-ca39-48d4-941c-86dc67ba9848_1344x325.png)](https://www.decodingai.com/)

SubscribeSign in

![User's avatar](https://substackcdn.com/image/fetch/$s_!pQz0!,w_64,h_64,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F0714d360-396c-4b41-a676-1b58dc1dc5f3_1470x1470.jpeg)

Discover more from Decoding AI Magazine

Join for content on designing, building, and shipping AI software. Learn AI engineering, end-to-end, from idea to production. Every Tuesday.

Over 41,000 subscribers

Subscribe

By subscribing, you agree Substack's [Terms of Use](https://substack.com/tos), and acknowledge its [Information Collection Notice](https://substack.com/ccpa#personal-data-collected) and [Privacy Policy](https://substack.com/privacy).

Already have an account? Sign in

# Stop Chasing the Perfect Ontology

### Start with a fixed, generic base and extend only when your data demands it.

[![Paul Iusztin's avatar](https://substackcdn.com/image/fetch/$s_!pQz0!,w_36,h_36,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F0714d360-396c-4b41-a676-1b58dc1dc5f3_1470x1470.jpeg)](https://substack.com/@pauliusztin)

[Paul Iusztin](https://substack.com/@pauliusztin)

May 26, 2026

46

10

5

Share

[![](https://substackcdn.com/image/fetch/$s_!HeOr!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fc87b2d2f-a13e-458f-8014-2d574171418c_1376x768.png)](https://substackcdn.com/image/fetch/$s_!HeOr!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fc87b2d2f-a13e-458f-8014-2d574171418c_1376x768.png)

For a while now I’ve been trying to build a proper memory layer on top of my research, writing, and content creation. Today it all lives in my Second Brain in Obsidian, where the primitives are files like notes, videos, and articles.

What I actually want is to shift those primitives from files to entities and relationships, such as people, locations, objects, topics, preferences, and facts. I want the memory to get closer to reality so I can watch how things evolve over time. I want a knowledge graph.

Everyone agrees knowledge graphs and GraphRAG provide a more performant substrate for a unified agent memory layer than plain RAG. But kicking one off is far harder. The resistance always collapses to the same wall: how you model your data. Your ontology is the hardest part of the system.

If you can’t define your ontology properly for your domain, the graph won’t represent the reality you want. The right entities and relationships simply aren’t there. As a result, GraphRAG ends up performing worse than the simple RAG you were trying to beat.

This translates straight to a memory layer. There’s no dodging it. Even if you stay file-only (a “virtual knowledge graph,” like an LLM knowledge base over your notes), you still hit the same data-modelling question: which primitives, and which entities, do you even extract?

The instinctive reaction is to design the perfect, complete ontology upfront. That’s exactly the trap that freezes the project.

The strategy is a not-overkill ontology. You need something flexible enough to kick off with almost no friction before you really know your domain, extending it with domain-specific detail as you explore your data.

Concretely, you use a small, fixed, generic, but extendable noun data model, known as POLE+O. Plus two core primitives, Preferences and Facts, for everything that doesn’t fit into the nouns.

You ship something that works, then add subtypes as a lightweight data-exploration step shows you where the generic types clash with your real data.

This approach lets you stand up a knowledge-graph memory layer for your own assistant without burning weeks on schema design. To build this, we first need to understand what an ontology actually is and why targeted models beat exhaustive ones.

## [Start Your Transition Into AI Engineering (Product)](https://academy.towardsai.net/pages/free-lesson-offer-2?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering)

[![](https://substackcdn.com/image/fetch/$s_!XTiA!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F977ee5b6-01a9-4bf9-a923-d092a8f5ac28_1114x1175.png)](https://substackcdn.com/image/fetch/$s_!XTiA!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F977ee5b6-01a9-4bf9-a923-d092a8f5ac28_1114x1175.png)

This article showed how to design the ontology your knowledge-graph memory needs. My [Agentic AI Engineering course](https://academy.towardsai.net/pages/free-lesson-offer-2?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering) shows the harness around it. I just released a free preview to build and run a working agent in 5 minutes.

You build a multi-agent system with two MCP servers (Research Agent + Writing Workflow), a deep research algorithm, an evaluator-optimizer loop, observability, and LLM-as-judge evals. Patterns required to ship AI.

Built for software, data engineers or scientists transitioning into AI engineering.

7 free lessons, 2 MCP agents ready for your GitHub portfolio. Part of our 35-lesson course. Rated 5/5 by 300+ students.

[Start the free preview →](https://academy.towardsai.net/pages/free-lesson-offer-2?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering)

## What Is an Ontology?

An ontology is the formal answer to 1 question. When you read the world, what do you write down as nodes, and what do you draw as edges? It specifies the kinds of things that exist in your domain, their properties, and how they relate to each other.

The ontology’s job is to map a targeted slice of the real world into the digital world. A good ontology is highly targeted to the problem you actually want to solve. If you over-model, you drown in noise and never ship. Plus, it get’s extremely expensive to extract and maintain the knoweldge graph. If you under-target, the graph doesn’t reflect the reality you care about.

[![An ontology is a deliberately narrow funnel from the real world into a queryable graph.](https://substackcdn.com/image/fetch/$s_!shkp!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F6da9e68c-1cec-4f99-afe9-ada0003fd270_1400x1202.png)](https://substackcdn.com/image/fetch/$s_!shkp!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F6da9e68c-1cec-4f99-afe9-ada0003fd270_1400x1202.png) _An ontology is a deliberately narrow funnel from the real world into a queryable graph._

Look at concrete, shipped ontologies for real-world proof. The [create-context-graph](https://create-context-graph.dev/docs/reference/domain-catalog) domain catalog made by Neo4j publishes 22 ready-made domain ontologies. Every single one lands at exactly 10 to 12 entity types. They use a shared 5-noun base plus only 5 to 7 domain-specific nouns.

For example, the Personal Knowledge domain models the world as Note, Contact, Project, Topic, Bookmark, and JournalEntry. The Agent Memory uses Agent, Conversation, Memory, ToolCall, and Session. The lesson here is that real ontologies are small on purpose. They capture only the entities required to answer the questions the system is designed for.

So if targeted and small is the goal, why does everyone — me included — reach for big and perfect first? That’s the trap.

## The Overkill Trap: Why My Knowledge Graphs Never Shipped

When I first encountered the ontology concept, I assumed I had to study my domain in depth. I thought I needed to model all of finance, for example, and design the ideal ontology before working with any real data. You can’t actually do that before you have a system running and data to look at. You just pile up assumptions that mostly turn out wrong.

I got frozen. Every knowledge-graph solution I started stayed on my laptop and never got used, because I was waiting on an ideal ontology I could never reach. Without understanding the ontology, I couldn’t even write a decent extraction step to populate it. I was deadlocked, bringing 0 value.

The breakthrough was realizing I need a couple of models that let me start generic and extend over time. As I get more data, analyze it, and actually understand my problem, the schema evolves. Let’s meet the base model that lets you start in 5 minutes instead of 5 weeks.

## The POLE+O Data Model

POLE+O is a tiny, fixed, top-level vocabulary that can classify almost anything you pull out of text. It stands for Person, Object, Location, Event, and Organization [\[2\]](https://neo4j.com/labs/agent-memory/explanation/poleo-model/). It originated in law-enforcement and intelligence analysis. The Organization type was added for general-purpose entity extraction. The point of a fixed base is queryability. There are always exactly 5 base nouns to filter on, so the graph stays answerable no matter how it grows underneath.

[![5 fixed base nouns, each extensible with optional subtypes — the base never changes, so every refinement is additive.](https://substackcdn.com/image/fetch/$s_!wK0q!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F34af01f1-f989-43ca-a1ca-f0e76cfa57fd_1400x1159.png)](https://substackcdn.com/image/fetch/$s_!wK0q!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F34af01f1-f989-43ca-a1ca-f0e76cfa57fd_1400x1159.png) _5 fixed base nouns, each extensible with optional subtypes_

Person covers people, aliases, and personas. Object covers physical or digital things. Location covers places, addresses, and regions. Event covers meetings, transactions, and incidents. Organization covers companies, teams, and institutions. Two or three of these catch the overwhelming majority of what a personal assistant needs.

Here are POLE+O’s five base types and the default subtypes each one ships with:

[![table](https://substackcdn.com/image/fetch/$s_!yyhn!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F7cc57663-f5d0-4f97-b81a-60c1bf2c34b9_1920x883.png)](https://substackcdn.com/image/fetch/$s_!yyhn!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F7cc57663-f5d0-4f97-b81a-60c1bf2c34b9_1920x883.png)

Here’s the beauty of this approach. You extend the base nouns with your own subtypes, and that’s how you tailor a generic ontology to your specific domain. It works exactly like object-oriented programming. You start from base classes you adopt without thinking. Then you subclass into specifics as your use case clarifies.

You can kick off with nothing extended and add concrete types only as you understand your data better. Neo4j’s [agent-memory](https://github.com/neo4j-labs/agent-memory) library uses precisely this approach. POLE+O is its default, swappable ontology.

The data-exploration workflow runs in a simple loop. First, kick off with generic POLE+O. Second, run an exploration extraction over your real data. Forget production reliability. You only care about understanding what’s there. Third, inspect the graph for clashes where the generic model lies about your data. Fourth, add or rename subtypes to fix each clash. Finally, repeat the process. You won’t get it perfect, and that’s the point. You iterate like any other AI app instead of freezing.

[![You don't theorize subtypes — you discover them by watching where generic POLE+O mislabels your real data, then patch the clash and loop.](https://substackcdn.com/image/fetch/$s_!pksj!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F3cbabfc9-cba1-433b-8ed2-b5d593ef3c81_1400x1351.png)](https://substackcdn.com/image/fetch/$s_!pksj!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F3cbabfc9-cba1-433b-8ed2-b5d593ef3c81_1400x1351.png) _You discover subtypes by watching where generic POLE+O mislabels your real data, then patch the clash and loop._

Look at named examples from real extraction runs. Claude Code comes back tagged as a Person when it’s clearly an Object. The “AI Engineer” conference lands as an Event when you wanted an Organization. DeepSeek is tagged a Person, not an Object.

Portugal and New York both get a flat Location label even though one’s a country and one’s a city. An agentic harness shows up as a generic Object when, for knowledge work, you’d rather have a Topic type. Each clash is a signal to add 1 subtype, not to redesign the whole schema.

POLE+O nouns and their subtypes cover the things in your world. But to fill in the gaps there are two specials tricks we have to go over.

## Preferences: The Things a Noun Likes

Preferences are the second family of entities you attach to the graph. They are things a noun likes or dislikes. A Preference is a characteristic of an entity. It represents a stance. The canonical case is a person who likes, prefers, or dislikes something.

Concretely, a Preference entity looks like this:

[![code](https://substackcdn.com/image/fetch/$s_!3KUZ!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F3a9cbc22-bb97-4bd4-99fa-a86ad59e6c60_2120x819.png)](https://substackcdn.com/image/fetch/$s_!3KUZ!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F3a9cbc22-bb97-4bd4-99fa-a86ad59e6c60_2120x819.png)

`category` groups the preference, `preference` is the statement itself, and `context` optionally records when or where it applies. `confidence` runs from 0 to 1. The `embedding` makes it semantically searchable.

Make it concrete. “Loves Italian food”, “prefers dark mode”, and “dislikes long meetings” are clear examples. Each is a stable stance the assistant should remember and adapt to.

By default, a Preference hangs off the Person. That’s the most common and useful case. You can extend preferences to other objects, like an Organization’s policies, a car’s settings, or an Event’s dress code.

Because I’m building a personal assistant, I start by attaching Preferences only to the Person. This keeps the graph clean, low-noise, and small. I’ll extend it later only when a concrete use case demands it.

[![Start simple — preferences attached only to the user; the dotted edges are extensions you add only when you need them.](https://substackcdn.com/image/fetch/$s_!hSPb!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F76d5574d-28fd-47a0-94e4-4a735f05dbd4_1400x879.png)](https://substackcdn.com/image/fetch/$s_!hSPb!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F76d5574d-28fd-47a0-94e4-4a735f05dbd4_1400x879.png) _Preferences attached only to the user. The dotted edges are extensions you add only when you need them._

Preferences are the personalization layer. They act as the memory of the user’s stances. They are the “sweet sauce” that makes every future response feel tailored.

There is one issue. Plenty of useful knowledge is just an atomic fact. Forcing all of that into the ontology is how graphs explode in complexity. The fix is a deliberately generic primitive.

## Facts: The Trick You Haven’t Thought Of

The Facts entity is the fallback for everything that doesn’t cleanly fit a noun or a Preference. You drop the claim into a generic Fact. This is the move that keeps the ontology small and stops you from over-thinking the schema.

A Fact is the closest thing to a classic-RAG chunk. An LLM produces each Fact during extraction. Each Fact holds a single, atomic concept which works like a charm via semantic search.

The beauty is that with facts you avoid the usual chunking errors, such as splits mid-thought, mixed concepts, and arbitrary boundaries. In reality, a Fact is a triplet. A subject, predicate, and object like “Eiffel Tower / is / 330m tall” gets embedded and stored as 1 granular unit.

Here is the shape of a Fact entity:

[![code](https://substackcdn.com/image/fetch/$s_!g51f!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fa162972e-7ad0-4275-94ec-4a9e654d287a_2120x819.png)](https://substackcdn.com/image/fetch/$s_!g51f!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fa162972e-7ad0-4275-94ec-4a9e654d287a_2120x819.png)

The triplet — `subject`, `predicate`, `object` — is the whole fact. `valid_from` and `valid_until` give it optional bi-temporal validity. The `embedding`, computed over the concatenated triplet, is what makes the fact retrievable by semantic search.

It’s confusing that we have a triplet stored as a node. But this is what it makes it flexible. We don’t worry about modeling these one-off triplets directly into the ontology, but the LLM extracts them as-is from the text.

Facts are usually wired to nothing. They have no relationships to other entities. They are retrieved only via semantic search and text search. A Fact stays in the graph but is independent of it. This works because a graph store runs vector search and graph traversal in the same query engine [\[4\]](https://neo4j.com/labs/agent-memory/explanation/graph-architecture/). Which means facts are retrieved only via semantic/text search.

[![Facts are atomic triplets retrieved by similarity and wired to nothing; POLE+O entities are reached by walking the graph. Same store, two retrieval modes.](https://substackcdn.com/image/fetch/$s_!-Wtw!,w_1456,c_limit,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fc37ed613-1a16-40f7-9607-2ed492a787cb_1400x1138.png)](https://substackcdn.com/image/fetch/$s_!-Wtw!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fc37ed613-1a16-40f7-9607-2ed492a787cb_1400x1138.png) _Facts are atomic triplets retrieved by similarity and wired to nothing; POLE+O entities are reached by walking the graph. Same store, two retrieval modes._

Facts let you ship a memory layer before you have the perfect ontology. Anything you can’t yet model degrades gracefully into a searchable atomic node instead of blocking the build. Early on, you lean on Facts. As the graph matures, claims migrate toward typed entities and edges. It costs nothing to schema and nothing to maintain when entities merge or get deleted.

## What’s Next

The takeaway is the posture. An ontology is a living artifact you bootstrap from a fixed generic base and grow through a data-exploration loop, exactly like any other AI application.

If you want to see the whole strategy implemented, the fastest path is to play with Neo4j’s [agent-memory](https://github.com/neo4j-labs/agent-memory) SDK or its MCP server. It uses POLE+O as a swappable default, subtypes as cheap extensions, and Preferences and Facts as first-class primitives. Studying it is what made all of this finally click for me.

I’m actively migrating my own Obsidian Second Brain toward the POLE+O, Preferences, and Facts primitives. This turns thousands of files into a graph I can actually traverse, visualize, and watch evolve over time.

_But here is what I’m wondering:_

> _**If you worked with Knowledge Graphs, what was your process in discovering your own ontology?**_

_Click the button below and tell me. I read every response._

[Leave a comment](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comments)

* * *

_Enjoyed the article? The most sincere compliment is to restack this for your readers._

[Share](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes?utm_source=substack&utm_medium=email&utm_content=share&action=share)

* * *

#### Whenever you’re ready, here is how I can help you

If you want to go from zero to shipping production-grade AI agents, check out my **[Agentic AI Engineering course](https://academy.towardsai.net/courses/agent-engineering?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering)**, built with Towards AI.

35 lessons. Three end-to-end portfolio projects. A certificate. And a Discord community with direct access to industry experts and me.

Built for software, data engineers or scientists transitioning into AI engineering.

_Rated 5/5 by 300+ students. The first 7 lessons are free:_

[Start here](https://academy.towardsai.net/courses/agent-engineering?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering)

_Not ready to commit?_ Start with our **[free Agentic AI Engineering Guide](https://email-course.towardsai.net/?ref=b3ab31&utm_source=decodingai&utm_medium=partner&utm_campaign=agent_engineering)**, a 6-day email course on the mistakes that silently break AI agents in production.

* * *

## References

1. Create Context Graph. (n.d.). Domain Catalog. create-context-graph. https://create-context-graph.dev/docs/reference/domain-catalog

2. Neo4j Labs. (n.d.). POLE+O Data Model. Neo4j Agent Memory. https://neo4j.com/labs/agent-memory/explanation/poleo-model/

3. Neo4j Labs. (n.d.). Neo4j Agent Memory. GitHub. https://github.com/neo4j-labs/agent-memory

4. Neo4j Labs. (n.d.). Why Neo4j? Graph-Native Memory Architecture. Neo4j Agent Memory. https://neo4j.com/labs/agent-memory/explanation/graph-architecture/


* * *

## Images

If not otherwise stated, all images are created by the author.

* * *

#### Subscribe to Decoding AI Magazine

Hundreds of paid subscribers

Join for content on designing, building, and shipping AI software. Learn AI engineering, end-to-end, from idea to production. Every Tuesday.

Subscribe

By subscribing, you agree Substack's [Terms of Use](https://substack.com/tos), and acknowledge its [Information Collection Notice](https://substack.com/ccpa#personal-data-collected) and [Privacy Policy](https://substack.com/privacy).

[![The Neural Agency's avatar](https://substackcdn.com/image/fetch/$s_!enw3!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F7131cc03-2f52-4a14-b90c-cfd0dc234210_144x144.png)](https://substack.com/profile/29490840-the-neural-agency)[![Alexandre Caminha's avatar](https://substackcdn.com/image/fetch/$s_!BdnQ!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fd0cfad7d-e0e7-4a62-a042-49db2daf95d1_640x640.jpeg)](https://substack.com/profile/3099761-alexandre-caminha)[![Prompting Into the Void's avatar](https://substackcdn.com/image/fetch/$s_!Vrv_!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F3185cba3-11b7-429d-8818-e989c0788617_950x950.png)](https://substack.com/profile/4591527-prompting-into-the-void)[![Yagyesh Srivastava's avatar](https://substackcdn.com/image/fetch/$s_!kiK5!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F7de68aa2-6cdf-4ec7-9b3d-77fd15d6bff1_864x866.jpeg)](https://substack.com/profile/55523719-yagyesh-srivastava)[![Richard Do's avatar](https://substackcdn.com/image/fetch/$s_!g00J!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F317179af-d60e-4774-887c-7d0a9105157e_1280x960.png)](https://substack.com/profile/33669847-richard-do)

46 Likes∙

[5 Restacks](https://substack.com/note/p-198955243/restacks?utm_source=substack&utm_content=facepile-restacks)

46

10

5

Share

PreviousNext

#### Discussion about this post

CommentsRestacks

![User's avatar](https://substackcdn.com/image/fetch/$s_!TnFC!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack.com%2Fimg%2Favatars%2Fdefault-light.png)

[![Isaac Vale's avatar](https://substackcdn.com/image/fetch/$s_!GA6i!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F03805a4f-c26d-47ff-a42d-e2d79cbb21bc_400x400.png)](https://substack.com/profile/86901934-isaac-vale?utm_source=comment)

[Isaac Vale](https://substack.com/profile/86901934-isaac-vale?utm_source=substack-feed-item)

[May 27](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comment/266124556 "May 27, 2026, 1:58 PM")

Liked by Paul Iusztin

Really fascinating article. Im also working my way into understanding how to create a real world, practical ontology. In my case I struggle with a normalized data mindset but this is a whole different game, we have to be able to tolerate ambiguity first and then let patterns emerge. Kind of like the stages of data pipeline architecture.

Like (1)

Reply

Share

[1 reply by Paul Iusztin](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comment/266124556)

[![Jon Rowlands's avatar](https://substackcdn.com/image/fetch/$s_!zIwe!,w_32,h_32,c_fill,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F5848a83c-e96c-4a8f-96ab-24992bd8c8c3_953x953.jpeg)](https://substack.com/profile/9771605-jon-rowlands?utm_source=comment)

[Jon Rowlands](https://substack.com/profile/9771605-jon-rowlands?utm_source=substack-feed-item)

[May 26](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comment/265718494 "May 26, 2026, 7:50 PM")

Liked by Paul Iusztin

Ontologies are useless but ontologizing is essential

Like (1)

Reply

Share

[1 reply by Paul Iusztin](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comment/265718494)

[8 more comments...](https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes/comments)

TopLatestDiscussions

[Build your Second Brain AI assistant](https://www.decodingai.com/p/build-your-second-brain-ai-assistant)

[Using agents, RAG, LLMOps and LLM systems](https://www.decodingai.com/p/build-your-second-brain-ai-assistant)

Feb 6, 2025•[Paul Iusztin](https://substack.com/@pauliusztin)

952

36

160

![](https://substackcdn.com/image/fetch/$s_!YzRk!,w_320,h_213,c_fill,f_auto,q_auto:good,fl_progressive:steep,g_center/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fc8ba5fa8-00aa-42fa-a187-62cb80fa7301_1166x1090.png)

[Stop Building AI Agents](https://www.decodingai.com/p/stop-building-ai-agents)

[Here’s what you should build instead](https://www.decodingai.com/p/stop-building-ai-agents)

Jun 26, 2025•[Hugo Bowne-Anderson](https://substack.com/@hugobowne)

193

13

25

![](https://substackcdn.com/image/fetch/$s_!hKEL!,w_320,h_213,c_fill,f_auto,q_auto:good,fl_progressive:steep,g_center/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F43169d77-56ed-4b9d-8a58-891a5a1039f8_847x480.png)

[Agentic AI Engineering Guide](https://www.decodingai.com/p/agentic-ai-engineering-guide-6-mistakes)

[The 6 critical mistakes that silently destroy agentic systems](https://www.decodingai.com/p/agentic-ai-engineering-guide-6-mistakes)

Mar 19•[Paul Iusztin](https://substack.com/@pauliusztin) and [Louis-François Bouchard](https://substack.com/@louisbouchard)

506

16

78

![](https://substackcdn.com/image/fetch/$s_!dUK-!,w_320,h_213,c_fill,f_auto,q_auto:good,fl_progressive:steep,g_center/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Ff23767fe-eb70-41ea-89c6-3f403021f221_1200x1200.png)

See all

### Ready for more?

Subscribe