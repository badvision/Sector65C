#!/bin/bash
# Working test with correct monitor syntax

set -e

JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_DIR="/Users/brobert/Documents/code/PointlessCrap/sectorc65"
COMPILER_BIN="$COMPILER_DIR/build/compiler.bin"
WORKSPACE="/tmp/claude/sectorc-65c02-port/iteration-1"

mkdir -p "$WORKSPACE"

echo "=== SectorC65 Working Test ==="
echo ""

# Build compiler
echo "[1/4] Building compiler..."
cd "$COMPILER_DIR"
make clean && make all
echo "✓ Compiler built: $(ls -lh $COMPILER_BIN | awk '{print $5}')"
echo ""

# Launch JACE
echo "[2/4] Running compiler on JACE..."
cd "$JACE_DIR"

cat > "$WORKSPACE/jace_test.txt" << 'JACE_SCRIPT'
reset
loadbin /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin 4000
monitor
4000G
quit
run 3000000
showtext
qq
JACE_SCRIPT

echo "Executing JACE..."
timeout 60 mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" < "$WORKSPACE/jace_test.txt" \
    > "$WORKSPACE/jace_output.txt" 2>&1

echo ""
echo "[3/4] Extracting results..."
echo ""
echo "=== FINAL TEXT SCREEN ==="
grep -A 26 "=== Text Screen" "$WORKSPACE/jace_output.txt" | tail -28 | head -26
echo ""

echo "[4/4] Verification:"
if grep -q "SECTORC65" "$WORKSPACE/jace_output.txt"; then
    echo "✓ SUCCESS: Compiler banner detected"
    BANNER_OK=1
else
    echo "✗ FAIL: Compiler banner not found"
    BANNER_OK=0
fi

if grep -q "DONE" "$WORKSPACE/jace_output.txt"; then
    echo "✓ SUCCESS: Execution completed"
    DONE_OK=1
else
    echo "✗ FAIL: Execution completion not found"
    DONE_OK=0
fi

echo ""
if [ $BANNER_OK -eq 1 ] && [ $DONE_OK -eq 1 ]; then
    echo "🎉 END-TO-END TEST PASSED! Compiler works on Apple IIe!"
    exit 0
else
    echo "❌ TEST FAILED - See output for details"
    echo "Full log: $WORKSPACE/jace_output.txt"
    exit 1
fi
