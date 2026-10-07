# ASD-STE100 — rule categories and sources

A summary of the public, official description of ASD-STE100 Simplified Technical English. It
paraphrases rule *categories*. It does not reproduce the standard's text or its dictionary.

## What the standard is

A controlled natural language, first released in 1986 as AECMA Document PSC-85-16598 by what is
now ASD, the AeroSpace and Defence Industries Association of Europe. European airlines asked for
it: most were staffed by non-native English speakers, and a misread maintenance instruction on an
aircraft can kill people.

The Simplified Technical English Maintenance Group maintains it. It has been free to download
since Issue 6 in 2013. The current edition is Issue 9, January 2025.

## Structure

- **53 writing rules in 9 sections**, covering word choice, grammar, sentence structure, and
  style.
- **A dictionary** of roughly 900 approved words, each restricted to one meaning and one part of
  speech, plus roughly 1,200 words to avoid with suggested replacements.
- **A terminology allowance**: an organisation may define its own dictionary of approved
  technical nouns and verbs beyond the base list, for vocabulary the base list cannot cover.

## The rule categories, paraphrased

**Word choice**

- Use approved words only in their approved meaning and part of speech.
- One word maps to exactly one meaning. Do not rely on context to disambiguate a word with
  several senses.
- Prefer the plainer, shorter, more common word over a formal or rare synonym.
- Use an approved verb for an action, not a noun derived from that verb (Rule 3.7).
- Do not form a phrasal verb by combining a verb and a preposition (Rule 9.3). Its meaning does
  not follow from the parts, and both non-native readers and translation systems mishandle it.

**Verb forms**

- Permitted: infinitive, imperative, simple present, simple past, simple future, and past
  participle used only as an adjective.
- Excluded: present perfect, past perfect, and other compound or auxiliary constructions.
- An "-ing" form is permitted only as a technical noun or part of one, never as a verb form.

**Voice**

- Active voice is required for procedures and instructions.
- Passive voice is allowed in descriptive text only, and only where the actor is genuinely
  unknown or irrelevant to the reader.

**Sentence structure**

- One instruction per sentence.
- About 20 words at most for a procedure or instruction; about 25 for descriptive text.
- Do not omit a verb, subject, or article to shorten a sentence. The standard warns explicitly
  that this creates ambiguity rather than clarity.
- Noun clusters are capped at 3 words.
- The semicolon is not permitted at all (Rule 8.1): "You can use all standard English punctuation
  marks but not the semicolon (;)." Write separate sentences. Every other standard mark, the em
  dash included, remains permitted.

**Paragraph and document structure**

- One topic per paragraph.
- About 6 sentences at most per paragraph.
- Use a numbered or bulleted list for a sequence, a set of conditions, or a complex enumeration,
  rather than burying it in prose.

**Safety instructions**

- A safety-critical instruction opens with the command or the condition. It is never buried
  mid-sentence.

## Why the dictionary is absent

ASD-STE100 is free to obtain and not free to redistribute. Issue 9, page 2, states that "no
reproduction or publication of it, in whole or in part, shall be made without the written
authority of an officer of ASD", and grants free reproduction rights only to eight listed
categories: ASD, AIA, and AIAC member associations and their member companies and customers,
member-state defence ministries, A4A, airworthiness authorities, and universities and research
institutes for educational purposes.

A commercial engineering team is in none of them. So the dictionary stays out of this repository,
and the word-choice rules here apply the underlying principle — pick the plainest, most common
word available, and use it the same way every time — rather than checking against a fixed list.

Where exact approved wording matters, request the standard from the official downloads page and
check word by word. Note that the page is a request form which emails a link, not a direct
download.

## Why this is used for output an agent produces

The standard was designed for a reader who cannot ask a follow-up question: a technician on a
tarmac, working from a manual, with no author to call. A person reading a status report at the end
of a long day is in a similar position, and a system parsing another system's output is in exactly
that position. The rules that protect a mechanic from a misread torque specification protect a
reader from a misread status claim.

## Sources

- ASD-STE100 official site — https://www.asd-ste100.org/
- About STE — https://www.asd-ste100.org/about_STE.html
- ASD Europe, Simplified Technical English —
  https://www.asd-europe.org/standards-specifications/simplified-technical-english/
- Simplified Technical English, Wikipedia —
  https://en.wikipedia.org/wiki/Simplified_Technical_English
- TechScribe, ASD-STE100 —
  https://www.techscribe.co.uk/techw/asd-simplified-technical-english.htm
- SKYbrary, Simplified Technical English —
  https://skybrary.aero/articles/simplified-technical-english-ste
