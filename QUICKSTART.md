# SectorC65 Quick Start

## Initial Setup ✅ COMPLETE

The development toolchain is set up and ready. All skeleton files are in place.

## What Works Now

- ✅ Project structure created
- ✅ ACME assembler verified (v0.97)
- ✅ Makefile with build system
- ✅ All include files with constants defined
- ✅ Skeleton source files for all compiler components
- ✅ Test harness framework with macros
- ✅ Example C programs (7 test cases)
- ✅ Clean build process (no errors)

## Build Commands

```bash
make              # Build compiler (default)
make test         # Build test binaries
make clean        # Remove build artifacts
make help         # Show all targets
```

## Current Build Outputs

```
build/compiler.bin      36KB    Main compiler (skeleton)
build/test_math.bin     43B     Math tests (stub)
build/test_compare.bin  60B     Comparison tests (stub)
build/*.lst             -       Assembly listings
```

## Next Implementation Steps

### 1. Runtime Library (Priority: HIGH)
Files: `src/runtime/math.asm`, `src/runtime/compare.asm`, `src/runtime/io.asm`

Implement:
- MUL16 (16-bit multiply)
- SHL16, SHR16 (bit shifts)
- ADD16, SUB16 (16-bit arithmetic)
- CMP_LT_SIGNED, CMP_GT_SIGNED (signed comparisons)
- CMP_EQ, CMP_NE (equality tests)
- print_string, print_hex16 (I/O helpers)

### 2. Test Framework (Priority: HIGH)
Files: `tests/test_math.asm`, `tests/test_compare.asm`

Write actual tests using harness macros:
```assembly
+test_start test_name
; Set up test data in R0, R1
jsr MUL16
+assert_eq_16 MULR, $2A, $00
+test_summary
```

### 3. Tokenizer (Priority: MEDIUM)
File: `src/tokenizer.asm`

Implement:
- skip_whitespace
- parse_identifier
- parse_number
- compute_hash
- Keyword recognition

### 4. Symbol Table (Priority: MEDIUM)
File: `src/symbols.asm`

Implement:
- sym_init
- sym_lookup
- sym_insert
- sym_get_address
- sym_get_type

### 5. Parser (Priority: MEDIUM)
File: `src/parser.asm`

Implement recursive descent parser:
- parse_program
- parse_declaration
- parse_statement
- parse_expression (with precedence)

### 6. Code Generator (Priority: MEDIUM)
File: `src/codegen.asm`

Implement:
- emit_byte, emit_word
- emit_load_var, emit_store_var
- emit_add, emit_subtract, emit_multiply
- emit_compare, emit_branch, emit_jump

### 7. Main Entry Point (Priority: LOW)
File: `src/main.asm`

Implement:
- Initialize compiler state
- Main compiler loop
- Source loading
- Output generation

## Test Strategy

1. **Unit Tests**: Test each runtime function individually
2. **Module Tests**: Test tokenizer, symbol table, parser separately
3. **Integration Tests**: Compile example C programs
4. **End-to-End**: Run generated code on emulator/hardware

## Development Workflow

```bash
# Edit source file (e.g., src/runtime/math.asm)
# Edit corresponding test (e.g., tests/test_math.asm)

make clean
make test

# If build succeeds:
# - Load build/test_math.bin into AppleWin or real hardware
# - Run at $4000 (JSR $4000)
# - Verify test output
```

## Memory Map Quick Reference

```
$0040-$007F : Compiler state (ZP_CODEGEN_PTR, ZP_SRC_PTR, etc.)
$0080-$009F : Virtual registers (R0-R3, PTR0-PTR3, MULR, etc.)
$0900-$2FFF : Generated code output (16KB)
$4000-$5FFF : Compiler code (8KB)
$6000-$9FFF : Source buffer (16KB)
$A000-$BEFF : Symbol table (8KB)
$D000-$DFFF : Runtime library (4KB in Language Card)
```

## Useful ACME Syntax

```assembly
; Zones for label scoping
!zone function_name {
  function_name:
    ...
  .local_label:
    ...
}

; Constants
CONST = $80

; Program counter
* = $4000

; Include files
!source "file.asm"

; Data
!byte $00, $01, $02
!word $1234
!text "Hello", 0
```

## AppleWin Testing

Once you have working test binaries:

```bash
# Load binary into AppleWin
# Press F2 (enter monitor)
# Type: BLOAD TEST_MATH.BIN,A$4000
# Type: CALL 16384  (or 4000G)
# Watch for test output
```

## Notes

- All skeleton files contain TODO comments marking what needs implementation
- Test harness is ready with assertion macros
- ACME zones prevent label conflicts between modules
- Build process is fast (< 1 second for full rebuild)
- cadius is available for creating ProDOS disk images later

## Getting Help

- ACME manual: `man acme` or https://sourceforge.net/projects/acme-crossass/
- 65C02 instruction set: http://6502.org/tutorials/65c02opcodes.html
- ProDOS MLI: https://prodos8.com/docs/techref/calls-to-the-mli/
