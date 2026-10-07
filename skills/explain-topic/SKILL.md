---
name: explain-topic
description: Explain one topic in more depth, at the level the reader needs. Use when the user says "explain that in more detail", "I don't understand", "what does that mean", "wait, what", or asks to be taught something.
---

# Explain a topic

The previous explanation did not land, or the topic needs real depth. Re-pitch it — do not
repeat it louder.

## Find out what is missing first

The four ways an explanation fails need four different repairs, and guessing wastes a round:

| What went wrong | The repair |
|---|---|
| Missing background | Give the prerequisite, then the topic |
| Too abstract | Give a concrete example from this codebase |
| Too much at once | One piece, checked, then the next |
| Wrong vocabulary | Use the project's words, not the general ones |

Where the confusion is not obvious from what they asked, ask. One question — "is it the retry
mechanism itself, or why we need one here?" — beats three paragraphs aimed at the wrong gap.

## Then explain

**Lead with the answer.** One or two sentences that would satisfy the reader if they read
nothing else. Reasoning after.

**Give the context they are missing, briefly.** Only the part this topic needs.

**Use one concrete example, from this codebase.** A real file, a real function, a real value.
`upload.ts:88` teaches more than "the handler". A general example about a shopping cart
teaches nothing about their system.

**Use the project's vocabulary.** If the code says `tenant`, do not say `organisation`. Where
the project has a domain glossary or a `CONTEXT.md`, take the words from there. Consistent
vocabulary is most of what makes an explanation land.

**Go one level deeper than asked, then stop.** The reader can ask again. Front-loading three
levels is why the first explanation failed.

**Name the thing.** Where a concept has a real name — memoisation, back-pressure, a seam, an
N+1 query — give it. A name is a handle for further reading and a word the team can use in
review.

**Say what you are unsure about.** "I am fairly sure the retry is there for the 504, but the
commit message does not say" is more useful than a confident guess. Keep the hedge.

## Then check

Close with something that surfaces a remaining gap, not with "let me know if you have
questions":

- "Does the part about the queue holding the job row make sense, or should I go into that?"
- "The bit I would expect to still be unclear is why the signature is regenerated. Is it?"

## Writing rules

`style/communication.md` applies in full and matters more here than anywhere:

- Short active sentences. One idea per sentence. Twenty-five words at most.
- One topic per paragraph, six sentences at most.
- A numbered list for anything with three or more steps.
- One word per concept — do not rotate synonyms mid-explanation, which is the fastest way to
  make a reader think two things are three.
- No phrasal verbs. "Start the job", not "spin up the job".
- No marketing adjectives, and no "simply", "just", or "obviously". They tell a stuck reader
  the problem is them.

## When teaching rather than answering

Where the user wants to learn a topic rather than unblock a question:

1. Agree the destination. What should they be able to do afterwards?
2. Establish what they already know, so you start at the right place.
3. Take one concept at a time. Explain, show it in the codebase, check understanding.
4. Give them something small to try, and let them try it before you continue.
5. Close with what to read next and what you deliberately left out.

## Diagrams

Reach for one where the topic is a shape rather than a sequence of facts — a state machine, a
data flow, a dependency graph, a request path. A Mermaid diagram under fifteen nodes helps. A
diagram of a two-step process does not.
