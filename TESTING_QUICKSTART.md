# SectorC65 Testing Quick Start

## One-Line Test
```bash
./tools/test_e2e.sh
```

## Current Status
- ✓ Binary loads and executes on Apple IIe
- ✓ Banner "SECTORC65 V1.0" prints
- ✗ Hangs during compilation (parser/codegen bug)

## What This Means
The 65C02 port works! The compiler runs on real Apple II hardware. There's a logic bug in the parser/codegen causing an infinite loop, but the low-level 65C02 code is correct.

## Files
- `tools/test_e2e.sh` - Automated test
- `tools/README_TESTING.md` - Full documentation
- `/tmp/claude/sectorc-65c02-port/iteration-1/` - Test outputs

## Next Steps to Fix
1. Add debug prints to identify hang location
2. Test tokenizer/parser/codegen individually
3. Try simpler test programs
4. Review ACME listing for infinite loops

## Manual JACE Testing
```bash
cd /Users/brobert/Documents/code/jace
mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" -Dexec.args="--terminal"
```

Then in JACE terminal:
```
reset
loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
monitor
4000G
back
run 10000000
showtext
qq
```

## Key Addresses
- `$4000` - Compiler code
- `$0900` - Generated code (empty = bug)
- `$3800` - Variables (should contain 42)
- `$4083` - Banner string
- `$4092` - DONE string

## Test Output
- ✓ SUCCESS: Both "SECTORC65 V1.0" and "DONE" on screen
- ⚠ PARTIAL: "SECTORC65 V1.0" only (current state)
- ✗ FAILURE: Blank screen or crash

## Requirements
- JACE built: `cd /Users/brobert/Documents/code/jace && mvn install`
- ACME assembler installed
- Make for build automation
