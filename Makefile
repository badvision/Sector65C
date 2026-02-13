# Makefile for SectorC65 - 65C02 C Compiler

ACME = acme
ACME_FLAGS = --cpu 65c02 -f plain

# Build directories
BUILD_DIR = build

# Source files
COMPILER_SRC = src/main.asm
COMPILER_MODULES = src/tokenizer.asm src/symbols.asm src/parser.asm src/codegen.asm src/error.asm
RUNTIME_MODULES = src/runtime/math.asm src/runtime/compare.asm src/runtime/io.asm
INCLUDES = src/include/zeropage.inc src/include/memory.inc src/include/tokens.inc

# Outputs
COMPILER_BIN = $(BUILD_DIR)/compiler.bin

.PHONY: all test clean help

all: $(COMPILER_BIN)

$(COMPILER_BIN): $(COMPILER_SRC) $(COMPILER_MODULES) $(RUNTIME_MODULES) $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/compiler.lst $(COMPILER_SRC)
	@echo "Compiler built: $@ ($$(wc -c < $@) bytes)"

# Integration test: build compiler, run on JACE Apple IIe emulator, verify results
# Requires: JACE_DIR environment variable pointing to JACE emulator checkout
test: $(COMPILER_BIN)
	@tools/run_tests.sh

clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned build artifacts"

help:
	@echo "SectorC65 Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build compiler (default)"
	@echo "  test         - Run integration tests on JACE emulator"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Testing requires JACE Apple IIe emulator:"
	@echo "  JACE_DIR=/path/to/jace make test"
