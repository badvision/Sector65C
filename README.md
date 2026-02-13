# SectorC65 - A C Compiler for the 65C02

A port of [SectorC](https://github.com/xorvoid/sectorc) (the x86 boot-sector C compiler) to the 65C02 processor, targeting the Apple IIe under ProDOS. Written entirely in 65C02 assembly, the compiler runs natively on the Apple IIe and compiles a subset of C directly to machine code in memory.

This is a hobby project exploring what's possible with a single-pass C compiler on an 8-bit machine with 128KB of bank-switched memory.

## What It Is

A working C compiler that runs on an Apple IIe (or emulator). It supports:

- **Variables**: `int` declarations with 16-bit signed values (up to 248 symbols per program)
- **Functions**: `void` functions with calls (no parameters yet)
- **Arithmetic**: `+`, `-`, `*`, `/`, `%` (division uses binary shift-and-subtract with result caching)
- **Unary minus**: `-expr`
- **Bitwise ops**: `&`, `|`, `^`, `<<`, `>>`
- **Comparisons**: `<`, `>`, `<=`, `>=`, `==`, `!=` (signed)
- **Logical ops**: `&&`, `||`
- **Control flow**: `if`, `while`, `return`
- **Pointers**: address-of (`&var`) and dereference (`*(int*)expr`)
- **Inline asm**: `asm 0xNN;` to emit raw bytes
- **Comments**: `//` line and `/* */` block comments
- **Number literals**: decimal and hex (`0xFF`)

The compiler is a recursive descent parser that emits 65C02 machine code in a single pass -- no AST, no intermediate representation, no linker. Source code goes in, executable bytes come out.

## What It Isn't (Yet)

- **No file I/O**: Source code is currently embedded in the compiler binary at compile time.
- **No function parameters or return values**: Functions are `void name() { ... }` only.
- **No arrays or strings**: Only scalar `int` (16-bit) variables.
- **No `else` clause**: `if` without `else`.
- **No `for` loops**: Use `while` instead.
- **No preprocessor**: No `#include`, `#define`, etc.
- **No separate compilation**: Everything compiles as a single translation unit.
- **No standard library**: No `printf`, `malloc`, etc. Use `asm` for direct hardware access.
- **Not self-hosting**: The compiler is hand-written in assembly, not compiled from C.

## Architecture

The compiler is built as a set of modules assembled with ACME into a single binary:

```
Source Text --> [Tokenizer] --> [Parser] --> [Code Generator] --> Executable Code
                                  |               |
                            [Symbol Table]   [Runtime Library]
```

### Memory Map

```
$0040-$007F : Compiler zero page (pointers, token state, temps)
$0080-$009F : Virtual registers (R0/R1 for expression evaluation)
$0900-$2FFF : Generated code output buffer
$3800-$3BFF : Variable storage (512 16-bit variables max)
$4000-$5FFF : Compiler code (~4KB)
$6000-$9FFF : Source code buffer (reserved for file loading)
$A000-$BEFF : Symbol table (256 entries x 32 bytes, hash + open addressing)
```

### How It Works

- **Tokenizer**: Table-driven operator matching, keyword recognition via string comparison, 8-bit hash for identifiers.
- **Parser**: Recursive descent with correct C operator precedence (12 levels from logical OR down to primary expressions). Assignment uses speculative lookahead with source pointer rollback.
- **Code Generator**: Emits inline 65C02 code for simple operations (add, sub, bitwise) and JSR calls for complex ones (multiply, divide, shifts, comparisons). Uses a two-register model (R0/R1 in zero page) for expression evaluation.
- **Runtime Library**: Includes 16-bit multiply (shift-and-add), divide/modulo (binary long division with result cache), shifts, signed comparisons, and logical operators. All routines are linked inline -- no Language Card or bank switching needed.
- **Symbol Table**: Open-addressed hash table with linear probing and full string comparison. Stores variable addresses and function entry points.

### Division Cache Optimization

When the compiler sees `q = a / b;` followed by `r = a % b;`, the division routine automatically detects that the same operands were just divided and returns the cached quotient/remainder without recomputing. This is a runtime optimization -- the compiler doesn't need to detect the pattern.

## Building

### Prerequisites

- [ACME cross-assembler](https://sourceforge.net/projects/acme-crossass/) (`brew install acme` on macOS)
- An Apple IIe emulator for testing (e.g., [JACE](https://github.com/badvision/jace))

### Build and Test

```bash
make all          # Build compiler binary
make test         # Run integration tests (requires JACE_DIR)
make clean        # Clean build artifacts
```

Output: `build/compiler.bin` (loads at $4000)

Testing requires the [JACE](https://github.com/badvision/jace) Apple IIe emulator:

```bash
JACE_DIR=/path/to/jace make test
```

The test suite compiles a comprehensive C program (20 variables, all operators), executes it on the emulated Apple IIe, and verifies the resulting variable values in memory.

### Running

Load the binary at $4000 and execute:

```
# In an Apple IIe emulator/monitor:
BLOAD COMPILER.BIN,A$4000
CALL 16384
```

The compiler will compile and execute the embedded test program from `tests/comprehensive.asm`. To use a different test program, edit `src/main.asm` and change the `!source` line to point to your test file.

## Project Structure

```
sectorc65/
  src/
    main.asm              Entry point, banner, test program include
    tokenizer.asm         Lexer: whitespace, comments, operators, identifiers, numbers
    symbols.asm           Hash table: lookup, insert, address allocation
    parser.asm            Recursive descent: declarations, statements, expressions
    codegen.asm           Machine code emission: loads, stores, operations, jumps
    error.asm             Error reporting (syntax, symbol, type, memory)
    include/
      zeropage.inc        Zero page allocation map
      memory.inc          Memory map constants and symbol table layout
      tokens.inc          Token type constants (34 token types)
    runtime/
      math.asm            MUL16, DIV16, MOD16, SHL16, SHR16, NEG16, LAND16, LOR16
      compare.asm         CMP_EQ16, CMP_LT16, CMP_GT16, CMP_LE16, CMP_GE16, CMP_NE16
      io.asm              ProDOS I/O stubs (PUTCHAR, PUTNUM)
  tests/
    comprehensive.asm     Default test program (20 variables, all operators)
    harness.asm           Test harness (unit test framework)
    test_*.asm            Unit tests for individual compiler modules
  tools/
    run_tests.sh          Integration test runner (JACE automation)
  Makefile                Build system
```

## Example Program

The compiler includes a comprehensive test program (`tests/comprehensive.asm`) that exercises all supported features. Here's a simpler example showing the C subset:

```c
int count;
int sum;
int x;

void main() {
  count = 0;
  sum = 0;
  while (count < 10) {
    count = count + 1;
    sum = sum + count;
  }
  x = 1000 / 7;       // x = 142, remainder cached for modulo
  if (x > 100 && sum == 55) {
    x = -1;            // success: x = 0xFFFF
  }
}
```

The full test program uses 20 variables and tests all arithmetic operators, comparisons, logical operations, control flow, and function calls.

## Lineage

Inspired by [SectorC](https://github.com/xorvoid/sectorc) by xorvoid -- a C compiler that fits in a 512-byte x86 boot sector. SectorC65 is not (and will never be) 512 bytes, but it shares the spirit of compiling C on minimal hardware with minimal tooling.

## License

MIT. Do whatever you want with it.
