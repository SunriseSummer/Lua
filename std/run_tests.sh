#!/bin/bash
# Run std collection tests

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LUA="${ROOT_DIR}/lua"
TEST_DIR="${SCRIPT_DIR}/tests"

cd "${ROOT_DIR}" || exit 1

echo "=== Running std Collection Test Suite ==="
echo "Using: ${LUA}"
echo

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

for f in "${TEST_DIR}"/*.cj; do
  name="std/tests/$(basename "$f")"
  TOTAL=$((TOTAL + 1))
  printf "Running %-45s ... " "$name"
  output=$("${LUA}" "$f" 2>&1)
  if echo "$output" | grep -q "^PASS:"; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES}\n--- ${name} ---\n${output}\n"
  fi
done

echo
echo "=== Results ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "Total:  ${TOTAL}"

if [ $FAIL -gt 0 ]; then
  echo
echo "=== Failures ==="
  echo -e "$FAILURES"
  exit 1
fi

echo
echo "All std collection tests passed!"
