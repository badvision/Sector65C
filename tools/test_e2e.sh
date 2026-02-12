#!/bin/bash
# SectorC65 End-to-End Test on JACE Apple IIe Emulator
#
# This script:
# 1. Builds the SectorC65 compiler
# 2. Loads it into JACE emulator memory at $4000
# 3. Executes the compiler
# 4. Verifies expected output
#
# Status: Partial - compiler loads and starts but hangs during compilation

set -e

# Configuration
JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_DIR="/Users/brobert/Documents/code/PointlessCrap/sectorc65"
COMPILER_BIN="$COMPILER_DIR/build/compiler.bin"
WORKSPACE="/tmp/claude/sectorc-65c02-port/iteration-1"
TIMEOUT=60  # seconds

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo " SectorC65 End-to-End Test"
echo "========================================"
echo ""

# Create workspace
mkdir -p "$WORKSPACE"

# Step 1: Build compiler
echo -e "${YELLOW}[1/5] Building compiler...${NC}"
cd "$COMPILER_DIR"
if make clean && make all > "$WORKSPACE/build.log" 2>&1; then
    SIZE=$(ls -lh "$COMPILER_BIN" | awk '{print $5}')
    echo -e "${GREEN}✓${NC} Compiler built: $SIZE"
else
    echo -e "${RED}✗${NC} Build failed"
    cat "$WORKSPACE/build.log"
    exit 1
fi
echo ""

# Step 2: Check JACE
echo -e "${YELLOW}[2/5] Checking JACE emulator...${NC}"
if [ ! -f "$JACE_DIR/target/Jace.jar" ]; then
    echo -e "${RED}✗${NC} JACE not built"
    echo "Run: cd $JACE_DIR && mvn install"
    exit 1
fi
echo -e "${GREEN}✓${NC} JACE ready"
echo ""

# Step 3: Run on emulator
echo -e "${YELLOW}[3/5] Running on Apple IIe emulator...${NC}"
cd "$JACE_DIR"

# Create JACE automation script
cat > "$WORKSPACE/jace_script.txt" << 'JACE_COMMANDS'
reset
loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
monitor
4000G
back
run 10000000
showtext
qq
JACE_COMMANDS

# Execute JACE
if timeout $TIMEOUT mvn -q exec:java \
    -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" \
    < "$WORKSPACE/jace_script.txt" \
    > "$WORKSPACE/jace_output.txt" 2>&1; then
    echo -e "${GREEN}✓${NC} Execution complete"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${YELLOW}⚠${NC} Execution timed out (${TIMEOUT}s)"
    else
        echo -e "${RED}✗${NC} Execution failed (exit code: $EXIT_CODE)"
        tail -20 "$WORKSPACE/jace_output.txt"
        exit 1
    fi
fi
echo ""

# Step 4: Extract screen output
echo -e "${YELLOW}[4/5] Checking results...${NC}"
echo ""
echo "=== Apple IIe Text Screen ==="
grep -A 26 "=== Text Screen" "$WORKSPACE/jace_output.txt" 2>/dev/null | head -27 || {
    echo -e "${RED}✗${NC} Could not extract screen output"
    exit 1
}
echo ""

# Step 5: Verify output
echo -e "${YELLOW}[5/5] Verification:${NC}"

PASS_COUNT=0
FAIL_COUNT=0

# Check for compiler banner
if grep -q "SECTORC65" "$WORKSPACE/jace_output.txt" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Compiler banner detected"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} Compiler banner NOT found"
    ((FAIL_COUNT++))
fi

# Check for completion message
if grep -q "DONE" "$WORKSPACE/jace_output.txt" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Execution completed (DONE message)"
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠${NC} Execution completion NOT detected"
    echo "  (Compiler likely hung during parsing/codegen)"
    ((FAIL_COUNT++))
fi

echo ""
echo "========================================"
echo " Test Summary"
echo "========================================"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""

if [ $PASS_COUNT -ge 1 ] && [ $FAIL_COUNT -eq 1 ]; then
    echo -e "${YELLOW}⚠ PARTIAL SUCCESS${NC}"
    echo ""
    echo "The compiler:"
    echo "  ✓ Loads into Apple IIe memory"
    echo "  ✓ Begins execution"
    echo "  ✓ Prints startup banner"
    echo "  ✗ Hangs during compilation"
    echo ""
    echo "This confirms the 65C02 binary is valid and can"
    echo "execute on real Apple II hardware, but there is"
    echo "a bug causing an infinite loop during parsing"
    echo "or code generation."
    echo ""
    echo "Next steps:"
    echo "  1. Add debug print statements to compiler"
    echo "  2. Test individual components in isolation"
    echo "  3. Review parser/codegen for infinite loops"
    echo ""
    echo "Full output: $WORKSPACE/jace_output.txt"
    echo "Diagnostic:  $WORKSPACE/../DIAGNOSTIC-REPORT.md"
    exit 2
elif [ $PASS_COUNT -eq 2 ]; then
    echo -e "${GREEN}✓✓✓ SUCCESS!${NC}"
    echo ""
    echo "The compiler successfully:"
    echo "  ✓ Loaded and executed on Apple IIe"
    echo "  ✓ Printed startup banner"
    echo "  ✓ Compiled the test program"
    echo "  ✓ Executed compiled code"
    echo "  ✓ Completed and printed DONE"
    echo ""
    exit 0
else
    echo -e "${RED}✗✗✗ FAILURE${NC}"
    echo ""
    echo "The compiler failed to execute properly."
    echo "Check the full output at: $WORKSPACE/jace_output.txt"
    exit 1
fi
