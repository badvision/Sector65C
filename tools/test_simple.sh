#!/bin/bash
# Simple test - load compiler directly without ProDOS

JACE_DIR="/Users/brobert/Documents/code/jace"
COMPILER_BIN="/Users/brobert/Documents/code/PointlessCrap/sectorc65/build/compiler.bin"

cd "$JACE_DIR"

# Test if compiler exists
if [ ! -f "$COMPILER_BIN" ]; then
    echo "ERROR: Compiler not built at $COMPILER_BIN"
    exit 1
fi

echo "Starting JACE terminal mode..."
echo "Will load compiler at \$4000 and execute at 16384 decimal"

# Use stdin approach for automation
timeout 30 mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" -Dexec.args="--terminal" <<JACE_END
# Reset system
reset
# Load compiler binary into memory at $4000
# TODO: We need to implement a memory load command, or use bootdisk with proper disk
showtext
qq
JACE_END

echo "Test complete"
