#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/tmp/logs"
GODOT_BIN="${GODOT_BIN:-godot}"
TEST_SCENE="${TEST_SCENE:-res://tests/TestRunner.tscn}"
QUIT_AFTER="${QUIT_AFTER:-3600}"
ENGINE_ERROR_REGEX="${ENGINE_ERROR_REGEX:-^(SCRIPT ERROR:|ERROR:|SHADER ERROR:|FATAL:)}"
ALLOW_ENGINE_ERROR_REGEX="${ALLOW_ENGINE_ERROR_REGEX:-}"
KEEP_HEADLESS_LOG_FILES="${KEEP_HEADLESS_LOG_FILES:-80}"
KEEP_RECORDING_ENTRIES="${KEEP_RECORDING_ENTRIES:-40}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
IMPORT_LOG="${LOG_DIR}/headless_import_${RUN_ID}.log"
TEST_LOG="${LOG_DIR}/headless_tests_${RUN_ID}.log"
SUMMARY_LOG="${LOG_DIR}/headless_summary_${RUN_ID}.log"
DO_IMPORT=1
USER_ARGS=()

prune_entries_by_count() {
	local keep="${1:-0}"
	local pattern="${2:-}"
	local rm_mode="${3:-file}"
	if [[ -z "${pattern}" ]]; then
		return
	fi
	if ! [[ "${keep}" =~ ^[0-9]+$ ]]; then
		return
	fi
	if [[ "${keep}" -eq 0 ]]; then
		keep=1
	fi
	if ! ls -1 ${pattern} >/dev/null 2>&1; then
		return
	fi
	local idx=0
	local list_cmd="ls -1t"
	if [[ "${rm_mode}" == "tree" ]]; then
		list_cmd="ls -1dt"
	fi
	${list_cmd} ${pattern} 2>/dev/null | while IFS= read -r stale; do
		idx=$((idx + 1))
		if [[ "${idx}" -le "${keep}" ]]; then
			continue
		fi
		if [[ "${rm_mode}" == "tree" ]]; then
			rm -rf "${stale}" || true
		else
			rm -f "${stale}" || true
		fi
	done
}

cleanup_artifacts() {
	prune_entries_by_count "${KEEP_HEADLESS_LOG_FILES}" "${LOG_DIR}/headless_*" "file"
	prune_entries_by_count "${KEEP_RECORDING_ENTRIES}" "${ROOT_DIR}/tmp/recordings/*" "tree"
}

trap cleanup_artifacts EXIT

for arg in "$@"; do
	case "$arg" in
		--skip-import)
			DO_IMPORT=0
			;;
		--suite=*)
			USER_ARGS+=("$arg")
			;;
		--user-arg=*)
			USER_ARGS+=("${arg#--user-arg=}")
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
if [[ ${#USER_ARGS[@]} -gt 0 ]]; then
	TEST_CMD+=("--" "${USER_ARGS[@]}")
fi
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

engine_errors=""
if [[ -n "${ALLOW_ENGINE_ERROR_REGEX}" ]]; then
	engine_errors="$(grep -nE "${ENGINE_ERROR_REGEX}" "${TEST_LOG}" | grep -Ev "${ALLOW_ENGINE_ERROR_REGEX}" || true)"
else
	engine_errors="$(grep -nE "${ENGINE_ERROR_REGEX}" "${TEST_LOG}" || true)"
fi
if [[ -n "${engine_errors}" ]]; then
	echo "[headless] engine/runtime errors detected in test log" >&2
	echo "${engine_errors}" | head -n 120 >&2
	exit 1
fi

echo "[headless] PASS"
