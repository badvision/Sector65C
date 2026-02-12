# SectorC65 Testing Infrastructure

## Overview

This directory contains end-to-end testing infrastructure for the SectorC65 compiler running on the JACE Apple IIe emulator.

## Prerequisites

1. **JACE Emulator**
   - Location: `/Users/brobert/Documents/code/jace/`
   - Built with Maven: `mvn install`
   - Terminal automation support required

2. **Build Tools**
   - ACME Assembler (for building compiler)
   - Make (for build automation)

3. **Disk Tools** (optional)
   - cadius (Homebrew): `brew install cadius`
   - For creating ProDOS disk images

## Test Scripts

### test_on_jace.sh
**Status**: Initial version - boots ProDOS disk
**Issue**: Requires bootable ProDOS system disk

### test_direct_load.sh
**Status**: Uses `loadbin` but incomplete execution

### test_working.sh
**Status**: Simplified direct load test

### test_final.sh
**Status**: Current best - direct binary load and execution

## Current Test Results (2026-02-12)

### What Works
- ✓ Compiler builds successfully (3,715 bytes)
- ✓ Binary loads into Apple IIe memory at $4000
- ✓ Execution starts correctly
- ✓ Banner "SECTORC65 V1.0" prints to screen
- ✓ ROM calls (COUT, CROUT) function properly

### What Fails
- ✗ Compiler hangs during compilation phase
- ✗ No code generated to $0900
- ✗ "DONE" message never prints
- ✗ Variable x never set to 42

### Diagnosis
The compiler successfully initializes and prints its banner, but enters an infinite loop during parsing or code generation. The test program `int x; void main() { x = 42; }` never gets compiled.

See `/tmp/claude/sectorc-65c02-port/iteration-1/DIAGNOSTIC-REPORT.md` for full analysis.

## Running Tests

### Quick Test
```bash
cd /Users/brobert/Documents/code/PointlessCrap/sectorc65
./tools/test_final.sh
```

### Manual Testing with JACE
```bash
cd /Users/brobert/Documents/code/jace

# Start JACE terminal
mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" -Dexec.args="--terminal"

# In JACE terminal:
JACE> reset
JACE> loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
JACE> monitor
*> 4000G
*> back
JACE> run 10000000
JACE> showtext
JACE> qq
```

### Debug with Breakpoints
```bash
# Create script with breakpoints at key functions
cat > /tmp/debug.txt << 'EOF'
reset
loadbin /path/to/compiler.bin 4000
monitor
break 400E   # After banner
break 4911   # codegen_init
break 40BF   # tokenize
break 44FB   # parse_program
4000G
cpu
back
qq
EOF

cd /Users/brobert/Documents/code/jace
mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" -Dexec.args="--terminal" < /tmp/debug.txt
```

## Test Environment

### Memory Map (Apple IIe)
```
$0000-$00FF  Zero Page
$0100-$01FF  Stack
$0200-$03FF  Input buffer / system
$0400-$07FF  Text screen page 1
$0800-$08FF  System
$0900-$2FFF  Generated code area (compiler output)
$3000-$37FF  System
$3800-$3BFF  Variable storage
$3C00-$3FFF  System
$4000-$5FFF  Compiler code (loaded here)
$6000-$9FFF  Source code buffer
$A000-$BEFF  Symbol table
$BF00-$BFFF  ProDOS global page
$C000-$CFFF  I/O space
$D000-$DFFF  Language Card (runtime library)
$E000-$FFFF  ROM
```

### JACE Commands Reference

#### Main Mode
- `reset` - Cold start Apple II
- `loadbin <file> <addr>` - Load binary to memory (addr in hex, no $)
- `run [cycles]` - Run CPU (default 1M cycles)
- `showtext` - Display text screen
- `monitor` - Enter monitor mode
- `qq` - Exit JACE

#### Monitor Mode
- `<addr>G` - Execute at address (e.g., `4000G`)
- `<addr>L` - Disassemble at address
- `<addr>.<addr>` - Examine memory range (e.g., `4000.4020`)
- `break <addr>` - Set breakpoint
- `rt <addr>` - Run until address
- `cpu` - Show CPU registers
- `back` - Return to main mode

## Known Issues

1. **Compiler Hangs**: Parser or codegen enters infinite loop
2. **No ProDOS Boot**: Test disk has no system files
3. **Monitor `showtext` Fails**: Must use from main mode, not monitor mode

## Next Steps

1. Add debug print statements to compiler:
   - After initialization
   - Before/after tokenization
   - Before/after parsing
   - Before/after code generation

2. Test individual compiler components in isolation

3. Try simpler test programs:
   - `void main() {}`
   - `void main() { return; }`

4. Review ACME listing for address conflicts

5. Check Language Card initialization on Apple IIe

## References

- JACE Documentation: `/Users/brobert/Documents/code/jace/CLAUDE.md`
- Compiler Source: `/Users/brobert/Documents/code/PointlessCrap/sectorc65/src/`
- Build System: `/Users/brobert/Documents/code/PointlessCrap/sectorc65/Makefile`
- Test Workspace: `/tmp/claude/sectorc-65c02-port/iteration-1/`
