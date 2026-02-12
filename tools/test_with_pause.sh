#!/bin/bash
# Test with CPU stepping and pausing to catch output

set -e

JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_DIR="/Users/brobert/Documents/code/PointlessCrap/sectorc65"
COMPILER_BIN="$COMPILER_DIR/build/compiler.bin"
WORKSPACE="/tmp/claude/sectorc-65c02-port/iteration-1"

mkdir -p "$WORKSPACE"

echo "=== SectorC65 Diagnostic Test ==="
echo ""

# Build
echo "[1/4] Building..."
cd "$COMPILER_DIR"
make clean && make all >/dev/null 2>&1
echo "✓ Built"

# Test execution
echo "[2/4] Testing on JACE..."
cd "$JACE_DIR"

# Try approach: load, set PC via registers, then run
cat > "$WORKSPACE/jace_cmd.txt" << 'JACE_SCRIPT'
reset
loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
monitor
registers pc 4000
back
run 500000
showtext
run 1000000
showtext
run 2000000
showtext
qq
JACE_SCRIPT

timeout 60 mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" < "$WORKSPACE/jace_cmd.txt" \
    > "$WORKSPACE/output.txt" 2>&1

echo "✓ Complete"
echo ""

# Show all screen states
echo "[3/4] Screen captures:"
grep -B 1 -A 26 "=== Text Screen" "$WORKSPACE/output.txt" | grep -A 26 "=== Text Screen" | tail -90
echo ""

# Check
echo "[4/4] Results:"
if grep -q "SECTORC65" "$WORKSPACE/output.txt"; then
    echo "✓ Found SECTORC65"
fi
if grep -q "DONE" "$WORKSPACE/output.txt"; then
    echo "✓ Found DONE"
fi

echo ""
echo "Full output: $WORKSPACE/output.txt"
