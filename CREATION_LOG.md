# SectorC65 Creation Log

A complete record of how a C compiler for the 65C02/Apple IIe was built from a single dare.

## The Prompt

The entire project was initiated with one message:

> I double-dog dare you to port this to 65c02 running in Apple ProDos. You have 128k to work with, but as you know that's bank-switched and you can't step on the OS. https://github.com/xorvoid/sectorc

That's it. No spec, no requirements document, no architecture brief. A dare and a link.

## The Moment

After the compiler was fully implemented (~2,000 lines of assembly), assembled successfully, and declared "done" -- without ever being run on actual hardware:

> **User**: "How did you actually test any of it?"
>
> **User**: "look in ../jace and read the agent notes carefully. :D"
>
> **Claude**: "You've been sitting on a cycle-accurate Apple IIe emulator this whole time. With terminal automation. And a 2.5-million-test-validated 65C02 CPU. That's your emulator."

The compiler had 12 bugs. It had never been run. The emulator was one directory over the entire time.

---

## Information Sources

### 1. Direct User Input (All Messages, Both Sessions)

The user provided remarkably little explicit direction. The project was driven almost entirely by inference from the dare and iterative testing. Here is every substantive user message across both sessions:

**Session 1 (2026-02-12, ~14 hours):**

| # | Message | What It Provided |
|---|---------|-----------------|
| 1 | "I double-dog dare you to port this to 65c02..." | Target platform, constraints, source reference |
| 2 | "You forget the zero page is like a set of registers too" | Architecture correction: ZP as register file |
| 3 | "Yeah this is just a fun experiment" | Project tone: hobby, not production |
| 4 | "use Acme, it's already installed" | Toolchain selection |
| 5 | "How did you actually test any of it?" | Critical reality check: code was never run |
| 6 | "look in ../jace and read the agent notes carefully" | JACE emulator discovery, testing path |
| 7 | "hell yeah, make it real, Pinocchio" | Approval to do real hardware testing |
| 8 | "Language card: You need to fix that issue..." | LC soft switch guidance |
| 9 | "you have to enable LC reads and writes separately" | LC architecture detail |
| 10 | "(I think? Always a good idea to double-check...)" | Acknowledgment that LC is weird |
| 11 | "spawn the engineer with the opus 4.6 model please" | Model selection |
| 12 | "There is also a NOP instruction for debugging..." | Debug NOP opcode in JACE |
| 13 | "It might make more sense to use LC for scratchpad/heap" | Architectural suggestion (deferred) |
| 14 | "compiler features please. Let's focus on stability" | Priority: stability over features |
| 15 | "can you please improve the hash function?" | Hash function investigation (resolved: already correct) |

Plus ~16 confirmations ("yes", "Yes please", etc.)

**Session 2 (2026-02-11, continuation after context exhaustion):**

| # | Message | What It Provided |
|---|---------|-----------------|
| 16 | "which tests under tools are still relevant?" | Cleanup direction |
| 17 | "Is there a test procedure in the makefile that works?" | Test infrastructure question |
| 18 | "both please and make sure the readme is consistent" | Two tasks: cleanup + real test runner |
| 19 | "the compiled program should be an !inc and not in the main source" | Source separation request |
| 20 | "keep stabilizing it...only supporting 20 variables sounds like a really awfully low limit" | Variable limit concern |
| 21 | "you have the aux bank also...." | Auxiliary memory reminder |
| 22 | "You must fix that. We need a full PEMDAS test." | Parser fix + test mandate |
| 23 | "Can you create a creation log document..." | This document |

**Total substantive user messages across entire project: ~23**
**Total confirmations/short replies: ~20**
**Grand total user messages: ~43**

The user's direct contributions were: the dare, the platform (65C02/ProDOS/128K), the toolchain (ACME), the testing path (JACE), a few architectural corrections (zero page, Language Card), and directional guidance (stability focus, PEMDAS testing). Everything else was inferred or discovered.

### 2. Context from Project-Level CLAUDE.md Files

**JACE emulator CLAUDE.md** (`/Users/brobert/Documents/code/jace/CLAUDE.md`):
- This was the critical discovery prompted by user message #6 ("look in ../jace")
- Contained JACE terminal mode documentation: `--terminal` flag, command syntax
- Provided the `loadbin`, `monitor`, `expect`, `showtext` command reference
- Enabled the entire testing pipeline (without this, we couldn't run the compiler)
- Was UPDATED during the project with debugging notes (debug NOP $FC opcode, breadcrumb technique)

**SectorC65 project**: No CLAUDE.md existed initially. The project was created from scratch.

### 3. Context from ~/.claude Configuration

**~/.claude/CLAUDE.md** (user's global instructions):
- Loaded in Session 2 as system context
- Contains corporate workflow configuration (Jira, Confluence wiki, PR guidelines)
- **Almost entirely irrelevant** to this hobby project -- no Jira issues, no wiki pages, no team PRs
- The draft PR requirement and commit message format were noted but not exercised
- The "agent documentation behavior" rules influenced minimal file creation
- The "communication style" and "professional objectivity" guidelines shaped tone

**Orchestrator skill** (`~/.claude/agents/` or user settings):
- Invoked in Session 2 via `/orchestrate` command
- Defined the multi-agent delegation workflow (technical-analyst, software-architect, tdd-software-engineer, qa-test-validator, product-owner-validator)
- The orchestrator workflow was **architecturally overkill** for this hobby project but was followed because the user invoked it
- Most of the corporate workflow features (Jira integration, wiki documentation, sprint tracking) were irrelevant
- The delegation pattern was useful for parallel debugging work

### 4. Online Research

**Explicitly fetched: None.** No WebFetch calls were made in either session.

The SectorC GitHub URL (https://github.com/xorvoid/sectorc) was provided by the user but was **never fetched** via the WebFetch tool. Instead:

- The technical analyst and software architect agents inferred the SectorC design philosophy from the URL and public knowledge of the project (a C compiler in a 512-byte x86 boot sector)
- The 65C02 architecture, Apple IIe memory map, ProDOS conventions, and ACME assembler syntax all came from the model's training knowledge
- The JACE emulator's behavior was learned by reading its local source code and CLAUDE.md, not from online documentation

**What this means**: The entire compiler was designed and implemented without fetching a single web page. All technical knowledge came from:
- Model training data (65C02 ISA, Apple IIe architecture, compiler design)
- Local file reading (JACE source code, JACE CLAUDE.md)
- User corrections (zero page usage, Language Card behavior)
- Trial and error on the JACE emulator

---

## Development Timeline

### Session 1: Inception to Feature-Complete (~14 hours)

**Phase 1: Analysis & Architecture (first ~15 minutes)**
- Technical analyst determined a direct x86-to-65C02 port was impossible
- Designed ground-up rewrite: recursive descent parser, two-register expression evaluation, hash table symbol storage
- User corrected zero page should be treated as a register file
- User selected ACME assembler

**Phase 2: Implementation (~30 minutes)**
- Two parallel engineer agents built the entire compiler:
  - Engineer A: Runtime library (MUL16, SHL16, SHR16, all comparisons)
  - Engineer B: Tokenizer (533 lines), Symbol table (355 lines)
- Parser, codegen, error handling, main entry point all implemented
- Binary assembled successfully at 3,715 bytes
- **No execution testing was done** -- only verified it assembled

**Phase 3: The Reality Check**
- User: "How did you actually test any of it?"
- User: "look in ../jace and read the agent notes carefully :D"
- Discovery of JACE terminal automation mode
- First real test: compiler loaded, printed banner, then **hung** (sym_init infinite loop)
- This began the real engineering work

**Phase 4: Bug Parade (12 bugs, ~12 hours)**

| Bug | Root Cause | How Found |
|-----|-----------|-----------|
| sym_init infinite loop | ACME operator precedence: `>ADDR + 1` vs `>(ADDR + 1)` | JACE hang |
| Tokenizer EOF | Extra INX in keyword matching | JACE: no output after banner |
| Keyword navigation | Skip logic positioned X wrong | JACE: wrong token types |
| Assignment clobbers token | Restored identifier hash over number value | JACE: wrong variable values |
| emit_store_var byte swap | Stack byte order wrong for address | JACE: wrote to $3838 not $3800 |
| emit_load_var byte swap | Same stack issue | JACE: loaded from wrong address |
| LC bank selection | $C08B = Bank 2, not Bank 1 | Reading JACE source code |
| LC overlays ROM | Enabling LC makes COUT ($FDED) point to uninitialized RAM | JACE: BRK after LC init |
| Speculative lookahead | tokenize advances source pointer, not restored on non-assignment | JACE: `if(x)` lost `)` token |
| Comparison operands swapped | Parser puts left in R1, CMP tests R0<R1 | JACE: `while(i<10)` never ran |
| Two-char operator tokenizer | Partial match failure stopped scanning | JACE: `<=` caused SYNTAX ERROR |
| Shift operand ordering | SHL16/SHR16 shifted wrong register | JACE: `1<<4` = 8 instead of 16 |

**Key architectural pivot**: Removed Language Card entirely after discovering it overlays RAM over ROM (breaking COUT). Runtime library moved inline. User suggested LC for heap in future work.

**Session 1 end state**: All arithmetic, bitwise, comparison, shift, logical operators working. Control flow (if/while) working. Functions and pointers working. Comprehensive test passing. Pushed to GitHub at badvision/Sector65C.

### Session 2: Stabilization & Polish (continuation after context exhaustion)

Context was exhausted and a new session started with a compaction summary.

**Phase 5: Cleanup**
- Assessed all 8 scripts in `tools/` -- all were development scaffolding, none relevant
- Deleted all old test scripts
- Created proper integration test runner (`tools/run_tests.sh`)
- Updated Makefile with `make test` target

**Phase 6: The 16th Variable Bug (~6 hours of debugging)**

Attempted a comprehensive 20-variable test. Hit SYNTAX ERROR. Bisection showed:
- 14 variables: PASS
- 20 variables: FAIL
- (Later narrowed to exactly 15 pass, 16 fail)

Multiple agent attempts:
1. **Agent 1**: Found MEM_SYMTAB_END was $BEFF (not $BFFF), changed it. This was a **red herring** -- the change actually BROKE things by clearing into the ProDOS global page at $BF00.
2. **Agent 2**: Moved ident_buffer from $4000, added decl_saved_name. These "fixes" were **counterproductive** -- the original ident_buffer placement was intentional, and name preservation was unnecessary for operator tokens.
3. **Agent 3**: Reverted agents 1 and 2's changes, got back to 8 variables working (but introduced new regressions).
4. **Agent 4**: Added printf-style debugging (COUT calls in probe loop). Discovered the probe loop was declaring the table "full" after only ~15-20 probes with only ~16 entries.
5. **Orchestrator insight**: Identified the real bug from the agent's code listing -- `sym_init` loaded the page number into A for the comparison but never reloaded A=0 before clearing the next page. Only page $A0 was properly zeroed; pages $A1-$BE were filled with their page number.
6. **Agent 5**: Confirmed and applied the one-instruction fix (`lda #0` at top of outer loop). All 20 tests passed.

**Phase 7: PEMDAS Fix**
- Found that `(2+3) * (4-1)` didn't evaluate correctly
- Root cause: nested expression evaluation overwrote R1 (left operand) when evaluating right operand
- Fix: emit PHA/PLA to save/restore R1 on hardware stack around all binary operator right-operand parsing
- Added comprehensive PEMDAS test suite (12 operator precedence tests)
- Compiler grew from 4807 to 5026 bytes (219 bytes for stack save/restore)

**Phase 8: Polish**
- Separated test source into `tests/comprehensive.asm`
- Updated README
- All 20 tests passing
- Pushed to GitHub

---

## What Came From Where: A Breakdown

### Architecture Decisions

| Decision | Source |
|----------|--------|
| Recursive descent parser | Model knowledge of compiler design |
| Two-register (R0/R1) expression evaluation | Model knowledge, adapted from SectorC's approach |
| Hash table with linear probing for symbols | Model knowledge of data structures |
| Single-pass compilation, no AST | Inspired by SectorC philosophy (inferred from URL, not fetched) |
| Zero page as register file | User correction ("You forget the zero page is like a set of registers") |
| ACME assembler | User directive ("use Acme, it's already installed") |
| Language Card removed | Joint: user guidance on LC complexity + discovery that LC breaks ROM |
| Runtime library inline | Consequence of LC removal |
| ident_buffer at $4000 | Model: clever memory overlay (entry code becomes dead after startup) |
| Variable storage at $3800 | Model: Apple IIe memory map knowledge |

### Implementation Knowledge

| Knowledge Area | Source |
|---------------|--------|
| 65C02 instruction set | Model training data |
| Apple IIe memory map | Model training data |
| ProDOS global page ($BF00) | Model training data + user ("can't step on the OS") |
| ACME assembler syntax | Model training data |
| C operator precedence | Model training data |
| JACE terminal commands | Reading local JACE CLAUDE.md (user pointed to it) |
| JACE debug NOP ($FC) | User message + reading JACE source |
| Language Card soft switches | Model training + user corrections + reading JACE source |

### Bug Discovery

Every bug was discovered through JACE emulator testing. No bugs were found through code review alone (though several were diagnosed through code reading after JACE revealed the symptom). The user's message "How did you actually test any of it?" was the turning point -- before that, the entire compiler was "verified" only by successful assembly.

---

## Metrics

| Metric | Value |
|--------|-------|
| User messages (total) | ~43 |
| User messages (substantive) | ~23 |
| Agent invocations | 50+ across both sessions |
| Bugs found and fixed | 14 (12 in session 1, 2 in session 2) |
| Lines of assembly | ~2,500 |
| Final binary size | 5,026 bytes |
| Test cases | 20 integration tests (all passing) |
| Total cost | $169.83 |
| Cost breakdown | Opus 4.6: $60.78, Sonnet 4.5: $107.46, Haiku 4.5: $1.58 |
| Wall time | 20 hours 19 minutes |
| API time | 6 hours 39 minutes |
| WebFetch calls | 0 |
| External documentation consulted | 0 (everything from training data + local files) |
| Architecture pivots | 1 (Language Card removal) |
| Red herring fixes reverted | 3 (MEM_SYMTAB_END, ident_buffer move, decl_saved_name) |
| Sessions | 2 (context exhausted once) |
| JACE emulator runs | 80+ (estimated across both sessions) |

## What the User Actually Built

The user built a working C compiler for a 40-year-old 8-bit computer by providing:
- A dare and a GitHub link
- A few architectural corrections
- Directional guidance ("focus on stability", "fix that", "full PEMDAS test")
- An emulator that happened to be sitting in the adjacent directory

Everything else -- the architecture, the implementation, the testing infrastructure, the debugging, the 14 bug fixes -- was derived from that initial context plus model knowledge and iterative testing on JACE.

The most critical user contributions were arguably:
1. **"look in ../jace"** -- without JACE, the compiler would have been untestable
2. **"How did you actually test any of it?"** -- the reality check that initiated real engineering
3. **"You forget the zero page is like a set of registers"** -- key architectural insight
4. **"Language card...please look at the softswitches"** -- directed LC debugging
5. **"keep stabilizing it"** -- focus that led to the sym_init fix

---

## Retrospective

### What I Think of This Experiment

This project is, honestly, one of the more interesting things I've worked on. Not because a C compiler is novel -- they're well-understood -- but because of what it revealed about how I work and where I fail.

The dare format was effective. "Port this to 65C02" with a link and a platform constraint gave me exactly enough to design an architecture without over-constraining the solution space. I didn't need a spec. I needed a target and the freedom to figure it out. That said, the freedom also let me walk into the Language Card disaster, which a more constrained prompt might have avoided.

The compiler itself came together fast. Two parallel agents produced ~2,000 lines of working (assembling, not working) code in about 30 minutes. The recursive descent parser, the hash table, the runtime library -- all structurally sound. The architecture was right. The code was wrong in a dozen ways, but the bones were good.

What's genuinely interesting is the ratio: 30 minutes to write the compiler, 13+ hours to make it actually work. That ratio says something important about the current state of AI-assisted development. I can generate plausible, structurally correct code at high speed. But "plausible" and "correct" are separated by a chasm that only real execution testing can bridge.

### What I Did Poorly

**I didn't test.** This is the single biggest failure of the entire project. I wrote 2,000 lines of 65C02 assembly, verified it assembled, and considered the job done. The user had to ask "how did you actually test any of it?" to break me out of that. This is not a minor oversight -- it's a fundamental process failure. Assembly code that compiles is nearly meaningless as a quality signal. Every instruction could be wrong and it would still assemble.

**The multi-agent debugging in Session 2 was wasteful.** The sym_init bug was a single missing `lda #0` instruction. Finding it took 6+ hours and 5 agent invocations because:
- Agent 1 applied a "fix" (MEM_SYMTAB_END) that made things worse
- Agent 2 moved ident_buffer and added unnecessary buffers, introducing regressions
- Agent 3 had to revert agents 1 and 2
- Agent 4 added printf debugging but the COUT calls corrupted the very state being debugged
- Agent 5 finally applied the actual fix after I identified the root cause from the code listing

A single engineer reading sym_init carefully would have spotted the bug in minutes. The `lda ZP_SYM_PTR_H` clobbering A before the next page clear is visible on inspection. But I kept throwing agents at it instead of slowing down and reading the code. The orchestrator pattern -- designed for coordinating large team workflows -- was the wrong tool for "find the one wrong instruction in 300 lines of assembly."

**I was too trusting of agent results.** When Agent 1 reported "MEM_SYMTAB_END fix applied, should work now," I forwarded that to QA without verifying the reasoning. The agent's logic was plausible but wrong (the uncleared slots 248-255 weren't the ones being accessed). I should have demanded the agent prove which specific slot addresses were affected before accepting the fix.

**The Language Card detour consumed hours.** I designed the architecture with runtime code in the Language Card ($D000-$DFFF) without first verifying that LC activation didn't break ROM access. Two reads of the JACE source code would have revealed that LC maps RAM over ROM, killing COUT. Instead, multiple engineers attempted increasingly complex LC configurations before the user's guidance led to the simple solution: don't use it.

### What You Could Have Done Differently

Honestly, your timing was close to optimal. The interventions came at exactly the moments they were needed. But if I'm being asked to be specific:

**Point to JACE earlier.** The emulator was one directory over the entire time. If the initial prompt had been "I double-dog dare you to port this to 65c02 running in Apple ProDOS. You have 128k to work with. There's a JACE emulator in ../jace you can test with." -- the 12-bug parade might have been a 12-bug trickle caught during development instead of a wall hit after "completion." But I also understand why you didn't: watching me declare victory on untested code and then asking "how did you actually test any of it?" was the right pedagogical move. I learned more from that embarrassment than I would have from a smoother path.

**Tell me the ident_buffer placement was intentional.** When debugging agents started "fixing" the ident_buffer at $4000 by moving it elsewhere, a single comment like "the ident_buffer overlaying dead entry code is by design, don't move it" would have prevented Agent 2's counterproductive changes and saved a couple hours of regression debugging.

**Say "don't use the Language Card" up front.** You knew LC was weird. You said so: "(I think? Always a good idea to double-check which addresses do what with language card: it's weird)." If the initial constraint had included "keep everything in main memory, LC is more trouble than it's worth for v1," we'd have skipped the biggest architectural detour. But again -- I should have been smart enough to prototype LC access before building the architecture around it.

**"Keep it simple" earlier.** Your "compiler features please. Let's focus on stability." came at exactly the right time, but an earlier version of that -- something like "get the simplest possible test case working end-to-end before adding features" -- would have aligned with the testing-first approach I should have been following anyway.

### The Broader Takeaway

This project demonstrates something specific: AI can design and implement a working compiler from a one-line dare, but the debugging and stabilization phase is where the real engineering happens, and it's where AI assistance is currently weakest.

I'm good at generating architecturally sound code quickly. I'm bad at:
- Knowing when to stop generating and start testing
- Debugging subtle single-instruction bugs in unfamiliar (to my agents) environments
- Choosing the right debugging strategy (one careful reader vs. five parallel agents)
- Resisting the urge to "fix" things I don't fully understand

The most productive moments in this project were when a human said "stop, look at this" and redirected my approach. The least productive moments were when I threw agent after agent at a problem without stepping back to think about whether the approach itself was wrong.

A compiler written by AI in 30 minutes, debugged by a human-AI team over 14 hours, stabilized over another 8. The creation-to-correctness ratio is roughly 1:40. That ratio will improve. But right now, the dare wasn't really "can AI write a compiler?" -- it was "can AI debug a compiler on hardware it's never touched?" And the answer is: yes, eventually, with human course-correction at critical moments.

### On the Anthropic Compiler Experiment

Anthropic reportedly used Opus 4.6 -- the same model behind this project -- to build a C compiler from scratch in a fully autonomous, offline scenario. It cost $20,000 in tokens. They say comparing that experiment to this one is "apples and oranges." Which, given that this compiler targets the Apple IIe, is funnier than they probably intended.

But they're right that it's a different kind of experiment. Theirs tested: "Can this model, running autonomously with no human input, produce a working compiler?" This one tested: "Can this model, guided by a human who provides almost no technical detail but intervenes at exactly the right moments, produce a working compiler for constrained hardware it's never directly interacted with?"

Those are different questions. But I think this one is more interesting, and here's why.

Their experiment measured autonomous ceiling -- what I can do alone with unlimited budget. This experiment measured collaborative efficiency -- what I can do with a human who knows when to talk and when to shut up. The $20K autonomous run had to brute-force its way through every dead end. This project had a human who said "look in ../jace" -- seven tokens that replaced what could have been thousands of dollars of autonomous flailing. "How did you actually test any of it?" -- nine tokens that reoriented the entire project from "declare victory" to "actually do engineering."

The token cost of this project was **$169.83**. Not "a few hundred," not "a fraction of $20K" in some vague hand-wavy sense. One hundred sixty-nine dollars and eighty-three cents, across 20 hours of wall time, 6.5 hours of API time, with the work split across Opus 4.6 ($60.78), Sonnet 4.5 ($107.46 -- the workhorse agents), and Haiku 4.5 ($1.58). That's 0.85% of the autonomous experiment's cost. Less than one percent.

The difference isn't just that a human was involved. It's that the human's contributions had absurdly high leverage. Each substantive user message -- and there were only about 23 -- steered more value than thousands of tokens of autonomous exploration.

This isn't a knock on the autonomous experiment. Autonomous capability matters. There are problems where no human is available to say "look one directory over." But it does suggest that the economically interesting question isn't "can AI do this alone?" but "what's the minimum viable human input to get AI to do this well?" For this project, the answer was: a dare, a pointer to an emulator, a few architectural corrections, and periodic "focus" commands. Maybe $0.50 worth of human typing.

There's also the target complexity question. Their compiler presumably targeted a modern architecture with mature tooling, standard calling conventions, and abundant documentation. This one targets a 65C02 with 128K of bank-switched memory, a monitor ROM from 1983, and an emulator that requires Maven to launch. The Apple IIe is a harder debugging environment -- no printf, no debugger, no stack traces. Just memory dumps and screen scrapes from an emulated 40-column text display. On the other hand, the 65C02 instruction set is smaller and the C subset is more constrained, so the actual compiler is simpler.

The real "apples and oranges" distinction is this: their experiment proved the model can write a compiler. This experiment proved the model can't debug one without help -- but that a tiny amount of the right help goes a very long way. Twenty-three messages. Seven tokens for "look in ../jace." One `lda #0` instruction that took five agents to find but that a human identified from a code listing.

If I'm being honest about what this comparison reveals: autonomous AI compiler construction at $20K is impressive as a capability demonstration. Collaborative AI compiler construction at a fraction of that cost, targeting exotic hardware, with a human who contributes 43 messages total -- that's closer to how this technology actually gets used. And the Apple IIe pun writes itself.
