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

# Test files
TEST_HARNESS = tests/harness.asm
TEST_MATH_SRC = tests/test_math.asm
TEST_COMPARE_SRC = tests/test_compare.asm
TEST_TOKENIZER_SRC = tests/test_tokenizer.asm
TEST_SYMBOLS_SRC = tests/test_symbols.asm

# Outputs
COMPILER_BIN = $(BUILD_DIR)/compiler.bin
TEST_MATH_BIN = $(BUILD_DIR)/test_math.bin
TEST_COMPARE_BIN = $(BUILD_DIR)/test_compare.bin
TEST_TOKENIZER_BIN = $(BUILD_DIR)/test_tokenizer.bin
TEST_SYMBOLS_BIN = $(BUILD_DIR)/test_symbols.bin

.PHONY: all test clean help

all: $(COMPILER_BIN)

$(COMPILER_BIN): $(COMPILER_SRC) $(COMPILER_MODULES) $(RUNTIME_MODULES) $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/compiler.lst $(COMPILER_SRC)
	@echo "Compiler built: $@ ($$(wc -c < $@) bytes)"

test: $(TEST_MATH_BIN) $(TEST_COMPARE_BIN) $(TEST_TOKENIZER_BIN) $(TEST_SYMBOLS_BIN)
	@echo "Tests assembled successfully"
	@echo "  $(TEST_MATH_BIN)"
	@echo "  $(TEST_COMPARE_BIN)"
	@echo "  $(TEST_TOKENIZER_BIN)"
	@echo "  $(TEST_SYMBOLS_BIN)"

$(TEST_MATH_BIN): $(TEST_MATH_SRC) $(TEST_HARNESS) src/runtime/math.asm $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/test_math.lst $(TEST_MATH_SRC)
	@echo "Built: $@"

$(TEST_COMPARE_BIN): $(TEST_COMPARE_SRC) $(TEST_HARNESS) src/runtime/compare.asm $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/test_compare.lst $(TEST_COMPARE_SRC)
	@echo "Built: $@"

$(TEST_TOKENIZER_BIN): $(TEST_TOKENIZER_SRC) $(TEST_HARNESS) src/tokenizer.asm $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/test_tokenizer.lst $(TEST_TOKENIZER_SRC)
	@echo "Built: $@"

$(TEST_SYMBOLS_BIN): $(TEST_SYMBOLS_SRC) $(TEST_HARNESS) src/symbols.asm $(INCLUDES)
	@mkdir -p $(BUILD_DIR)
	$(ACME) $(ACME_FLAGS) -o $@ -l $(BUILD_DIR)/test_symbols.lst $(TEST_SYMBOLS_SRC)
	@echo "Built: $@"

clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned build artifacts"

help:
	@echo "SectorC65 Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build compiler (default)"
	@echo "  test         - Build test binaries"
	@echo "  clean        - Remove build artifacts"
	@echo "  help         - Show this help message"
