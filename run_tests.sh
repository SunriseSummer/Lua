#!/bin/bash
# Run all Cangjie test cases
# Usage: ./run_tests.sh [lua_binary]

LUA=${1:-./lua}
TESTDIR="cangjie-tests"
PASSED=0
FAILED=0
ERRORS=""

echo "=== Running Cangjie Test Suite ==="
echo "Using: $LUA"
echo ""

for test in $TESTDIR/*.cj; do
    name=$(basename "$test")
    printf "Running %-35s ... " "$name"
    output=$($LUA "$test" 2>&1)
    status=$?
    
    if [ $status -eq 0 ] && echo "$output" | grep -q "^PASS:"; then
        echo "PASS"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL"
        FAILED=$((FAILED + 1))
        ERRORS="$ERRORS\n--- $name ---\n$output\n"
    fi
done

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "=== Failures ==="
    echo -e "$ERRORS"
    exit 1
fi

echo ""
echo "All tests passed!"
exit 0
