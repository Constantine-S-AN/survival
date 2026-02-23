#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/tmp/logs"
GODOT_BIN="${GODOT_BIN:-godot}"
TEST_SCENE="${TEST_SCENE:-res://tests/TestRunner.tscn}"
QUIT_AFTER="${QUIT_AFTER:-3600}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
IMPORT_LOG="${LOG_DIR}/headless_import_${RUN_ID}.log"
TEST_LOG="${LOG_DIR}/headless_tests_${RUN_ID}.log"
SUMMARY_LOG="${LOG_DIR}/headless_summary_${RUN_ID}.log"
DO_IMPORT=1

for arg in "$@"; do
	case "$arg" in
		--skip-import)
			DO_IMPORT=0
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 2
			;;
	esac
done

mkdir -p "${LOG_DIR}"

echo "[headless] run_id=${RUN_ID}"
if [[ "${DO_IMPORT}" -eq 1 ]]; then
	echo "[headless] prewarm import"
	set +e
	"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import >"${IMPORT_LOG}" 2>&1
	import_exit=$?
	set -e
	if [[ ${import_exit} -ne 0 ]]; then
		echo "[headless] import failed (exit=${import_exit})" >&2
		tail -n 80 "${IMPORT_LOG}" || true
		exit ${import_exit}
	fi
	echo "[headless] import log: ${IMPORT_LOG}"
fi

echo "[headless] run tests scene=${TEST_SCENE} quit_after=${QUIT_AFTER}"
TEST_CMD=("${GODOT_BIN}" --headless --path "${ROOT_DIR}" "${TEST_SCENE}" --quit-after "${QUIT_AFTER}")
set +e
if command -v timeout >/dev/null 2>&1; then
	timeout --preserve-status "$((QUIT_AFTER + 120))" "${TEST_CMD[@]}" >"${TEST_LOG}" 2>&1
	test_exit=$?
else
	"${TEST_CMD[@]}" >"${TEST_LOG}" 2>&1
	test_exit=$?
fi
set -e

grep -E "Tests finished|failed=|PASS:|FAIL:" "${TEST_LOG}" | tail -n 120 >"${SUMMARY_LOG}" || true

echo "[headless] summary:"
if [[ -s "${SUMMARY_LOG}" ]]; then
	cat "${SUMMARY_LOG}"
else
	echo "(no summary lines captured)"
fi

echo "[headless] test log: ${TEST_LOG}"
echo "[headless] summary log: ${SUMMARY_LOG}"

if [[ ${test_exit} -ne 0 ]]; then
	echo "[headless] runner exited with code ${test_exit}" >&2
	tail -n 120 "${TEST_LOG}" || true
	exit ${test_exit}
fi

if ! grep -q "Tests finished. failed=0" "${TEST_LOG}"; then
	echo "[headless] tests reported failures" >&2
	tail -n 120 "${TEST_LOG}" || true
	exit 1
fi

echo "[headless] PASS"
