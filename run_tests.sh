#!/bin/bash
# Run all Cangjie test cases

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUA="${SCRIPT_DIR}/lua"
TEST_DIR="${SCRIPT_DIR}/cangjie-tests"

echo "=== Running Cangjie Test Suite ==="
echo "Using: ${LUA}"
echo

PASS=0
FAIL=0
TOTAL=0
FAILURES=""

# Run main tests (skip utility files starting with '_')
for f in "${TEST_DIR}"/*.cj; do
  name=$(basename "$f")
  [[ "$name" == _* ]] && continue
  TOTAL=$((TOTAL + 1))
  printf "Running %-40s ... " "$name"
  output=$("$LUA" "$f" 2>&1)
  if echo "$output" | grep -q "^PASS:"; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    FAILURES="${FAILURES}\n--- ${name} ---\n${output}\n"
  fi
done

# Run ext-features tests
if [ -d "${TEST_DIR}/ext-features" ]; then
  echo
  echo "=== Extended Features Tests ==="
  for f in "${TEST_DIR}/ext-features"/*.cj; do
    name="ext-features/$(basename "$f")"
    TOTAL=$((TOTAL + 1))
    printf "Running %-40s ... " "$name"
    output=$("$LUA" "$f" 2>&1)
    if echo "$output" | grep -q "^PASS:"; then
      echo "PASS"
      PASS=$((PASS + 1))
    else
      echo "FAIL"
      FAIL=$((FAIL + 1))
      FAILURES="${FAILURES}\n--- ${name} ---\n${output}\n"
    fi
  done
fi

# Run usages tests
if [ -d "${TEST_DIR}/usages" ]; then
  echo
  echo "=== Usage Examples ==="
  for f in "${TEST_DIR}/usages"/*.cj; do
    [ -f "$f" ] || continue
    name="usages/$(basename "$f")"
    TOTAL=$((TOTAL + 1))
    printf "Running %-40s ... " "$name"
    output=$("$LUA" "$f" 2>&1)
    if echo "$output" | grep -q "^PASS:"; then
      echo "PASS"
      PASS=$((PASS + 1))
    else
      echo "FAIL"
      FAIL=$((FAIL + 1))
      FAILURES="${FAILURES}\n--- ${name} ---\n${output}\n"
    fi
  done
fi

# Run diagnosis tests (error detection and reporting)
if [ -d "${TEST_DIR}/diagnosis" ]; then
  echo
  echo "=== Diagnosis Tests ==="
  for f in "${TEST_DIR}/diagnosis"/*.cj; do
    [ -f "$f" ] || continue
    name="diagnosis/$(basename "$f")"
    TOTAL=$((TOTAL + 1))
    printf "Running %-40s ... " "$name"
    output=$(timeout 30 "$LUA" "$f" 2>&1)
    if echo "$output" | grep -q "^PASS:"; then
      echo "PASS"
      PASS=$((PASS + 1))
    else
      echo "FAIL"
      FAIL=$((FAIL + 1))
      FAILURES="${FAILURES}\n--- ${name} ---\n${output}\n"
    fi
  done
fi

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
echo "All tests passed!"
