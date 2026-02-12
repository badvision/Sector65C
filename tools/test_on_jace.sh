#!/bin/bash
# End-to-end test of SectorC65 compiler on JACE emulator

set -e  # Exit on error

JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_DIR="/Users/brobert/Documents/code/PointlessCrap/sectorc65"
COMPILER_BIN="$COMPILER_DIR/build/compiler.bin"
TEST_DISK="$COMPILER_DIR/build/sectorc65_test.po"
WORKSPACE="/tmp/claude/sectorc-65c02-port/iteration-1"

mkdir -p "$WORKSPACE"

echo "=== SectorC65 End-to-End Test ==="
echo ""

# Step 1: Build compiler
echo "[1/6] Building compiler..."
cd "$COMPILER_DIR"
make clean && make all
if [ ! -f "$COMPILER_BIN" ]; then
    echo "ERROR: Compiler build failed"
    exit 1
fi
echo "✓ Compiler built: $(ls -lh $COMPILER_BIN | awk '{print $5}')"
echo ""

# Step 2: Create test disk with compiler
echo "[2/6] Creating test disk image..."
rm -f "$TEST_DISK"
cadius CREATEVOLUME "$TEST_DISK" SECTORC65 140KB > /dev/null
cp "$COMPILER_BIN" "$COMPILER_DIR/build/COMPILER#064000"
cadius ADDFILE "$TEST_DISK" /SECTORC65 "$COMPILER_DIR/build/COMPILER#064000" > /dev/null
echo "✓ Disk created with compiler binary"
cadius CATALOG "$TEST_DISK"
echo ""

# Step 3: Launch JACE and test
echo "[3/6] Launching JACE emulator..."
cd "$JACE_DIR"

# Create JACE automation script
cat > "$WORKSPACE/jace_commands.txt" << 'JACE_SCRIPT'
# Boot the test disk
bootdisk d1 /Users/brobert/Documents/code/PointlessCrap/sectorc65/build/sectorc65_test.po
# Wait for boot to complete (run some cycles)
run 500000
# Show screen to see what happened
showtext
# Try to BLOAD and run (send keystrokes)
key "BLOAD COMPILER,A$4000\n"
run 100000
showtext
key "CALL 16384\n"
run 2000000
showtext
# Exit
qq
JACE_SCRIPT

echo "Executing JACE automation..."
timeout 60 mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" < "$WORKSPACE/jace_commands.txt" \
    > "$WORKSPACE/jace_output.txt" 2>&1

echo ""
echo "[4/6] JACE execution complete"
echo ""

# Step 4: Analyze output
echo "[5/6] Analyzing test results..."
echo "=== JACE Output ==="
cat "$WORKSPACE/jace_output.txt"
echo ""

# Step 5: Check for expected output
echo "[6/6] Verification..."
if grep -q "SECTORC65 V1.0" "$WORKSPACE/jace_output.txt"; then
    echo "✓ Compiler banner detected"
else
    echo "✗ Compiler banner NOT found"
fi

if grep -q "DONE" "$WORKSPACE/jace_output.txt"; then
    echo "✓ Execution completion detected"
else
    echo "✗ Execution completion NOT found"
fi

echo ""
echo "=== Test Complete ==="
echo "Full output saved to: $WORKSPACE/jace_output.txt"
