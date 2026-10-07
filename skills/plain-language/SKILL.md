---
name: plain-language
description: Rewrite English so it can only be read one way. Use when text reads as dense, hedged, or easy to misparse; when writing an error message, tool description, or inter-agent instruction; or when the user asks for a plain-language, STE, or ASD-STE100 rewrite. Not for creative or marketing copy.
license: MIT
source: "Adapted from github.com/danyuchn/asd-ste100-skill (MIT). Encodes the rule categories of ASD-STE100 Issue 9; ASD's approved-word dictionary is not reproduced."
---

# Plain language

ASD-STE100 Simplified Technical English is a controlled language the aerospace and defence
industry built to stop maintenance technicians misreading instructions. It removes the two
largest sources of misreading: words with more than one meaning, and sentences with more than
one possible structure.

This skill applies that discipline to a different reader: a person under pressure, or a
downstream system, parsing a string with no way to ask a follow-up question. If a technician
can read "close the valve" as an adjective — the valve that is near — rather than a command,
so can anything else.

The standing rules for all output are `style/communication.md`. This skill is the on-demand
rewrite, with the mode split and the diff format.

## Pick a mode first

**Strict** — error messages, tool and function descriptions, procedures, safety text,
instructions passed between systems. Anywhere a wrong reading has a cost. Every rule, including
the length caps and the one-word-one-meaning discipline.

**Flavoured** — READMEs, PR descriptions, commit bodies, changelogs, explanatory prose. Every
structural rule in full; the word-choice rules as advisory. Prose needs some range, and a strict
rewrite of prose reads as a personality transplant rather than a clarification.

Infer the mode from the text type. State the choice only when the user asked for the rule table.

## Structural rules — apply these

| Rule | Do | Not |
|---|---|---|
| Active voice | "The agent deletes the file." | "The file is deleted." Passive only where the actor is genuinely unknown |
| No phrasal verbs | "Remove the panel." "Start the job." | "Take off the panel." "Spin up the job." A two-word verb means something the parts do not predict |
| One instruction per sentence | "Open the file. Read line 3." | "Open the file and read line 3, then check it matches" |
| Sentence length | 20 words for instructions, 25 for description | Long compound and subordinate chains |
| No semicolons | Separate sentences | Any semicolon. The standard bans the mark outright, not only as a clause join. Every other mark, the em dash included, stays permitted |
| Noun clusters | 3 words at most: "fuel pump valve" | "high pressure fuel pump inlet valve assembly" |
| No ellipsis | Keep the subject, verb, and article explicit even where it reads longer | Dropping words to save space: "files not backed up will be lost" — which files? |
| Keep modality | "The request **may have** failed" stays as it is | Promoting a hedge to a fact, or inventing a certainty the source did not state |
| Paragraphs | One topic, 6 sentences at most | Multi-topic paragraphs |
| Lists | A numbered or bulleted list for 3 or more steps or conditions | A sequence buried inside one prose sentence |

## Word choice — a direction, not a check

These rules are defined by ASD's approved dictionary, which this skill deliberately does not
reproduce. Without it they degrade from a checkable standard into a preference for plain words.
Apply them as a direction of travel, and never imply dictionary compliance.

| Rule | Do | Not |
|---|---|---|
| One word, one meaning | Pick one verb for one action and reuse it | Rotating "check", "verify", and "confirm" for the same action |
| One part of speech | "Apply oil to the valve" | "Oil the valve" — prefer the noun form where both read equally well |
| Verb, not noun | "Analyze the log." | "Perform an analysis of the log." |
| Domain terms | Keep the necessary technical noun, and define it once | Jargon that is never defined |

## Simple tenses, with one exception

The standard permits the infinitive, imperative, simple present, simple past, simple future, and
past participle as an adjective. It excludes the present perfect and other compound forms: "we
received the report", not "we have received the report".

An aircraft manual never needs the present perfect, so the exclusion costs the standard nothing.
Other text is not so lucky. "The job has completed" — and its output is available now — and "the
job completed" — at some past point — are different statements, and status text often needs the
first.

**Where the compound form carries information the simple form cannot, keep it and say you kept
it.** Elsewhere, follow the rule.

## Scan for six habits

Each is mechanical: you can point at the exact word or mark that breaks it.

1. **Synonym rotation** — one thing gets several names ("the user", "the customer", "the
   client"). The reader cannot tell whether that is one thing or three. Pick one, use it every
   time.
2. **Hedge stacking** — qualifiers pile up until the sentence asserts nothing: "it is important
   to note that this may potentially help to improve". State the claim, or delete it.
3. **Nominalization** — an action frozen into a noun: "perform an analysis of", "provides
   assistance to". Use the verb.
4. **Marketing adjectives** — words claiming quality instead of showing it: seamless, robust,
   powerful, cutting-edge, effortless, blazing-fast. Delete, or replace with the measurement that
   earns the claim.
5. **Run-on sentences** — several ideas joined by dashes. One idea per sentence.
6. **Soft phrasal verbs** — spin up, reach out, dive into, kick off, leverage. Use the plain verb.

## Process

1. Pick the mode.
2. Read the input once for meaning. Do not start rewriting before you know what it must still say
   afterwards.
3. Walk it sentence by sentence, flagging every structural violation and every habit above. In
   flavoured mode, flag the word-choice rules without enforcing them.
4. Rewrite each flagged sentence, preserving the meaning exactly.
   - **Check modality before committing to a rewrite.** A hedge carries the author's confidence,
     and confidence is content. A shorter sentence that promotes a hedge to a fact is not a
     simplification — it is a different claim. This is the most common way a well-meant rewrite
     goes wrong, because a hedge is exactly what a length cap tempts you to cut.
   - **Add no fact the source did not state.** A rewrite that reads better because it supplies a
     cause, a frequency, or a mechanism has stopped being a rewrite.
   - Where a rewrite would drop necessary precision — a safety condition, a scope qualifier, a
     number — keep the longer phrasing and flag it.
5. Output the rewritten text.
6. Where the input already complies, say so. Do not force changes onto compliant text.

## Output

**By default: the rewritten text, and nothing else.** Most callers want something they can paste
straight into an error string, a description, or a document. No preamble, no mode announcement,
no violation count, no closing offer to explain.

The one permitted addition: where step 4 kept a longer phrasing deliberately, one line after the
text, prefixed `Kept as-is:`, naming the phrase and the precision that would have been lost.

**On request: the rule table.** When the user asks to see the reasoning — "show the diff", "which
rules did it break", "before and after" — output this instead:

```markdown
| Rule | Original | Rewritten |
|---|---|---|
| Present perfect | "We have received your request." | "We received your request." |
| Noun cluster (4+) | "the agent task queue priority handler" | "the handler that sets task-queue priority" |

Mode: strict. 7 violations.
```

Follow it with one line on anything you deliberately did not simplify, and why.

## Boundaries

**This skill will:**

- Rewrite dense or ambiguous English into short, single-meaning, active sentences.
- Preserve every fact, condition, and scope qualifier.
- Preserve the strength of every hedge, and add no claim the source did not make.
- Suggest a one-line glossary entry for a domain term that must stay.

**This skill will not:**

- Reproduce ASD's approved dictionary, or claim compliance with it. See
  `references/writing-rules.md` for why.
- Rewrite creative, marketing, or persuasive copy, where voice and nuance are the point.
- Drop a safety condition, exception, or qualifier to shorten a sentence. It flags the trade-off
  instead.
- Turn "may have failed" into "failed".
- Make weak content true or useful. These rules fix the *form* of a text, not its substance. A
  hollow paragraph rewritten under them becomes a short, clean, well-punctuated hollow paragraph.
  Where the text has nothing to say, say that rather than polishing it.
- Shorten past the point of clarity. Removing ambiguity is the goal; cutting words is only the
  method. Stop when the sentence is unambiguous, not when it is shortest.

## Reference

`references/writing-rules.md` — the 9 rule sections, the dictionary structure, and the licensing
reason the dictionary is absent.
