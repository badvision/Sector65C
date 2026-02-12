#!/bin/bash
# Test using JACE's loadbin command to directly load the compiler

set -e

JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_DIR="/Users/brobert/Documents/code/PointlessCrap/sectorc65"
COMPILER_BIN="$COMPILER_DIR/build/compiler.bin"
WORKSPACE="/tmp/claude/sectorc-65c02-port/iteration-1"

mkdir -p "$WORKSPACE"

echo "=== SectorC65 Direct Load Test ==="
echo ""

# Build compiler
echo "[1/4] Building compiler..."
cd "$COMPILER_DIR"
make clean && make all
echo "✓ Compiler built"
echo ""

# Launch JACE with direct binary loading
echo "[2/4] Launching JACE and loading compiler directly..."
cd "$JACE_DIR"

cat > "$WORKSPACE/jace_direct.txt" << 'JACE_SCRIPT'
# Reset system
reset
# Load compiler binary directly at $4000
loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
# Show initial screen state
showtext
# Execute the compiler (JSR to $4000)
# We need to set PC to $4000 and run
# Use monitor commands to set PC and execute
monitor
g 4000
quit
# After execution, run for some cycles
run 3000000
# Show final screen
showtext
# Exit
qq
JACE_SCRIPT

timeout 60 mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" < "$WORKSPACE/jace_direct.txt" \
    > "$WORKSPACE/jace_output.txt" 2>&1

echo ""
echo "[3/4] Execution complete"
echo ""

# Analyze output
echo "[4/4] Results:"
echo "=== Text Screen Output ==="
grep -A 30 "=== Text Screen" "$WORKSPACE/jace_output.txt" | tail -35
echo ""

if grep -q "SECTORC65" "$WORKSPACE/jace_output.txt"; then
    echo "✓ SUCCESS: Compiler banner found!"
else
    echo "✗ Compiler banner not found"
fi

if grep -q "DONE" "$WORKSPACE/jace_output.txt"; then
    echo "✓ SUCCESS: Execution completed!"
else
    echo "✗ Execution completion message not found"
fi

echo ""
echo "Full output: $WORKSPACE/jace_output.txt"
