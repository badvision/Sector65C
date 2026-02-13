#!/bin/bash
# SectorC65 Integration Test Runner
# Builds the compiler, runs it on JACE Apple IIe emulator, and verifies results
#
# Usage: JACE_DIR=/path/to/jace ./tools/run_tests.sh
#    or: JACE_DIR=/path/to/jace make test

# Find project root (script is in tools/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPILER_BIN="$PROJECT_DIR/build/compiler.bin"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    NC=''
fi

# --- Check prerequisites ---

if [ -z "$JACE_DIR" ]; then
    echo "ERROR: JACE_DIR not set"
    echo ""
    echo "Set it to the path of your JACE emulator checkout:"
    echo "  export JACE_DIR=/path/to/jace"
    echo "  make test"
    echo ""
    echo "Or: JACE_DIR=/path/to/jace make test"
    exit 1
fi

if [ ! -d "$JACE_DIR" ]; then
    echo "ERROR: JACE_DIR does not exist: $JACE_DIR"
    exit 1
fi

if [ ! -f "$COMPILER_BIN" ]; then
    echo "ERROR: Compiler not built at $COMPILER_BIN"
    echo "Run 'make' first."
    exit 1
fi

# --- Run on JACE ---

echo "=== SectorC65 Integration Test ==="
echo ""
echo "Compiler: $(wc -c < "$COMPILER_BIN" | tr -d ' ') bytes"
echo "Emulator: $JACE_DIR"
echo ""

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Running compiler on Apple IIe emulator..."

cd "$JACE_DIR"

# Find timeout command (GNU coreutils)
TIMEOUT_CMD=""
if command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout 120"
elif command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout 120"
fi

$TIMEOUT_CMD mvn -q exec:java -Dexec.mainClass="jace.JaceLauncher" \
    -Dexec.args="--terminal" > "$TMPDIR/output.txt" 2>&1 <<EOF
reset
loadbin $COMPILER_BIN 4000
monitor
4000G
back
run 100000000
showtext
monitor
3800.3827
back
qq
EOF

JACE_EXIT=$?
if [ $JACE_EXIT -eq 124 ]; then
    echo -e "${RED}FAIL${NC}: JACE timed out (120 seconds)"
    exit 1
elif [ $JACE_EXIT -ne 0 ]; then
    echo -e "${RED}FAIL${NC}: JACE exited with code $JACE_EXIT"
    cat "$TMPDIR/output.txt"
    exit 1
fi

# --- Check compiler execution ---

if ! grep -q "SECTORC65" "$TMPDIR/output.txt"; then
    echo -e "${RED}FAIL${NC}: Compiler did not start (no banner)"
    cat "$TMPDIR/output.txt"
    exit 1
fi

if ! grep -q "DONE" "$TMPDIR/output.txt"; then
    echo -e "${RED}FAIL${NC}: Compilation/execution did not complete"
    if grep -q "SYNTAX ERROR" "$TMPDIR/output.txt"; then
        echo "Compiler reported: SYNTAX ERROR"
    elif grep -q "ERROR" "$TMPDIR/output.txt"; then
        echo "Compiler reported an error"
    fi
    grep -A 5 "=== Text Screen" "$TMPDIR/output.txt" 2>/dev/null
    exit 1
fi

echo "Compiler executed successfully"
echo ""

# --- Parse memory dump ---

# Extract memory dump lines (format: "*3800: XX XX XX ..." or "3810: XX XX XX ...")
BYTES=()
while IFS= read -r line; do
    # Strip ASCII representation after " | " if present
    line=$(echo "$line" | sed 's/ |.*//')
    # Strip address prefix (optional *, 4 hex digits, colon, spaces)
    hex=$(echo "$line" | sed 's/^[*]*[0-9A-Fa-f]*[: -]* *//' | tr -s ' ')
    for byte in $hex; do
        if [[ $byte =~ ^[0-9A-Fa-f]{2}$ ]]; then
            BYTES+=("$byte")
        fi
    done
done < <(grep -E '^[*]?[0-9A-Fa-f]{4}[-: ]' "$TMPDIR/output.txt")

if [ ${#BYTES[@]} -lt 40 ]; then
    echo -e "${RED}FAIL${NC}: Memory dump too short (got ${#BYTES[@]} bytes, need 40)"
    echo ""
    echo "Raw output:"
    cat "$TMPDIR/output.txt"
    exit 1
fi

# Get 16-bit little-endian value at variable index
get_word() {
    local idx=$(($1 * 2))
    local lo="${BYTES[$idx]}"
    local hi="${BYTES[$idx+1]}"
    printf "%d" "0x${hi}${lo}"
}

# --- Verify results ---

# Test definitions: var_name:description:var_index:expected_value
# 20 variables test with PEMDAS, function calls, and all operators
TESTS=(
    "a:paren_override:0:20"
    "b:while_loop_final:1:11"
    "c:div_before_sub:2:17"
    "d:left_to_right:3:25"
    "e:nested_parens:4:15"
    "f:complex_pemdas:5:12"
    "g:mult_add_mixed:6:26"
    "h:double_paren_add:7:18"
    "i:negation:8:65535"
    "j:mult_paren_right:9:50"
    "k:div_in_parens:10:3"
    "l:left_assoc_div:11:5"
    "m:left_shift:12:256"
    "n:right_shift:13:16"
    "o:comparisons:14:6"
    "p:sum_1_to_10:15:55"
    "q:logical_and:16:1"
    "r:logical_or:17:1"
    "s:double_paren_mult:18:15"
    "t:func_call:19:30005"
)

PASS=0
FAIL=0

echo "Results:"
echo ""

for test in "${TESTS[@]}"; do
    IFS=':' read -r var desc idx expected <<< "$test"
    actual=$(get_word $idx)
    if [ "$actual" -eq "$expected" ]; then
        printf "  ${GREEN}PASS${NC}  %-2s = %-5d  (%s)\n" "$var" "$actual" "$desc"
        ((PASS++))
    else
        printf "  ${RED}FAIL${NC}  %-2s = %-5d  expected %-5d  (%s)\n" "$var" "$actual" "$expected" "$desc"
        ((FAIL++))
    fi
done

echo ""
echo "=============================="
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}ALL $PASS TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}$FAIL FAILED${NC}, $PASS passed"
    exit 1
fi
