#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/godot_env.sh"
LOG_DIR="${ROOT_DIR}/tmp/logs"
GODOT_BIN="$(resolve_godot_bin "${GODOT_BIN:-}")"
TEST_SCENE="${TEST_SCENE:-res://tests/TestRunner.tscn}"
QUIT_AFTER="${QUIT_AFTER:-3600}"
EXTRA_TEST_SCRIPT="${EXTRA_TEST_SCRIPT:-res://tests/night_v3_seed_replay_smoke.gd}"
EXTRA_TEST_PASS_MARKER="${EXTRA_TEST_PASS_MARKER:-Night V3 seed replay smoke PASS}"
SECOND_EXTRA_TEST_SCRIPT="${SECOND_EXTRA_TEST_SCRIPT:-res://tests/night_v3_objective_pack_smoke.gd}"
SECOND_EXTRA_TEST_PASS_MARKER="${SECOND_EXTRA_TEST_PASS_MARKER:-Night V3 objective pack smoke PASS}"
THIRD_EXTRA_TEST_SCRIPT="${THIRD_EXTRA_TEST_SCRIPT:-res://tests/night_destroy_nodes_smoke.gd}"
THIRD_EXTRA_TEST_PASS_MARKER="${THIRD_EXTRA_TEST_PASS_MARKER:-Night destroy-nodes smoke PASS}"
ENGINE_FAILURE_REGEX="${ENGINE_FAILURE_REGEX:-^(SCRIPT ERROR:|SCRIPT WARNING:|ERROR:|WARNING:|SHADER ERROR:|FATAL:|Leaked instance:|ObjectDB instances leaked at exit|Orphan StringName:|StringName: [0-9]+ unclaimed string names at exit\\.)}"
ALLOW_ENGINE_FAILURE_REGEX="${ALLOW_ENGINE_FAILURE_REGEX:-\\[profile\\] profile parse failed, attempting backup restore:}"
KEEP_HEADLESS_LOG_FILES="${KEEP_HEADLESS_LOG_FILES:-80}"
KEEP_RECORDING_ENTRIES="${KEEP_RECORDING_ENTRIES:-40}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
IMPORT_LOG="${LOG_DIR}/headless_import_${RUN_ID}.log"
TEST_LOG="${LOG_DIR}/headless_tests_${RUN_ID}.log"
SUMMARY_LOG="${LOG_DIR}/headless_summary_${RUN_ID}.log"
EXTRA_TEST_LOG=""
SECOND_EXTRA_TEST_LOG=""
THIRD_EXTRA_TEST_LOG=""
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
if [[ -n "${EXTRA_TEST_SCRIPT}" ]]; then
	EXTRA_TEST_NAME="$(basename "${EXTRA_TEST_SCRIPT}")"
	EXTRA_TEST_NAME="${EXTRA_TEST_NAME//[^A-Za-z0-9._-]/_}"
	EXTRA_TEST_LOG="${LOG_DIR}/headless_extra_${EXTRA_TEST_NAME%.*}_${RUN_ID}.log"
fi
if [[ -n "${SECOND_EXTRA_TEST_SCRIPT}" ]]; then
	SECOND_EXTRA_TEST_NAME="$(basename "${SECOND_EXTRA_TEST_SCRIPT}")"
	SECOND_EXTRA_TEST_NAME="${SECOND_EXTRA_TEST_NAME//[^A-Za-z0-9._-]/_}"
	SECOND_EXTRA_TEST_LOG="${LOG_DIR}/headless_extra_${SECOND_EXTRA_TEST_NAME%.*}_${RUN_ID}.log"
fi
if [[ -n "${THIRD_EXTRA_TEST_SCRIPT}" ]]; then
	THIRD_EXTRA_TEST_NAME="$(basename "${THIRD_EXTRA_TEST_SCRIPT}")"
	THIRD_EXTRA_TEST_NAME="${THIRD_EXTRA_TEST_NAME//[^A-Za-z0-9._-]/_}"
	THIRD_EXTRA_TEST_LOG="${LOG_DIR}/headless_extra_${THIRD_EXTRA_TEST_NAME%.*}_${RUN_ID}.log"
fi

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

engine_failures=""
if [[ -n "${ALLOW_ENGINE_FAILURE_REGEX}" ]]; then
	engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${TEST_LOG}" | grep -Ev "${ALLOW_ENGINE_FAILURE_REGEX}" || true)"
else
	engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${TEST_LOG}" || true)"
fi
if [[ -n "${engine_failures}" ]]; then
	echo "[headless] engine/runtime failures detected in test log" >&2
	echo "${engine_failures}" | head -n 120 >&2
	exit 1
fi

if [[ -n "${EXTRA_TEST_SCRIPT}" ]]; then
	echo "[headless] run extra script=${EXTRA_TEST_SCRIPT} quit_after=${QUIT_AFTER}"
	EXTRA_CMD=("${GODOT_BIN}" --headless --path "${ROOT_DIR}" -s "${EXTRA_TEST_SCRIPT}" --quit-after "${QUIT_AFTER}")
	set +e
	if command -v timeout >/dev/null 2>&1; then
		timeout --preserve-status "$((QUIT_AFTER + 120))" "${EXTRA_CMD[@]}" >"${EXTRA_TEST_LOG}" 2>&1
		extra_test_exit=$?
	else
		"${EXTRA_CMD[@]}" >"${EXTRA_TEST_LOG}" 2>&1
		extra_test_exit=$?
	fi
	set -e

	{
		echo
		echo "[extra] ${EXTRA_TEST_SCRIPT}"
		grep -E "PASS:|FAIL:|Night V3 seed replay smoke" "${EXTRA_TEST_LOG}" | tail -n 160 || true
	} >>"${SUMMARY_LOG}"
	echo "[headless] extra summary:"
	grep -E "PASS:|FAIL:|Night V3 seed replay smoke" "${EXTRA_TEST_LOG}" | tail -n 160 || true

	echo "[headless] extra log: ${EXTRA_TEST_LOG}"

	if [[ ${extra_test_exit} -ne 0 ]]; then
		echo "[headless] extra script exited with code ${extra_test_exit}" >&2
		tail -n 160 "${EXTRA_TEST_LOG}" || true
		exit ${extra_test_exit}
	fi

	if ! grep -q "${EXTRA_TEST_PASS_MARKER}" "${EXTRA_TEST_LOG}"; then
		echo "[headless] extra script did not report success marker" >&2
		tail -n 160 "${EXTRA_TEST_LOG}" || true
		exit 1
	fi

	if [[ -n "${ALLOW_ENGINE_FAILURE_REGEX}" ]]; then
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${EXTRA_TEST_LOG}" | grep -Ev "${ALLOW_ENGINE_FAILURE_REGEX}" || true)"
	else
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${EXTRA_TEST_LOG}" || true)"
	fi
	if [[ -n "${engine_failures}" ]]; then
		echo "[headless] engine/runtime failures detected in extra test log" >&2
		echo "${engine_failures}" | head -n 120 >&2
		exit 1
	fi
fi

if [[ -n "${SECOND_EXTRA_TEST_SCRIPT}" ]]; then
	echo "[headless] run extra script=${SECOND_EXTRA_TEST_SCRIPT} quit_after=${QUIT_AFTER}"
	SECOND_EXTRA_CMD=("${GODOT_BIN}" --headless --path "${ROOT_DIR}" -s "${SECOND_EXTRA_TEST_SCRIPT}" --quit-after "${QUIT_AFTER}")
	set +e
	if command -v timeout >/dev/null 2>&1; then
		timeout --preserve-status "$((QUIT_AFTER + 120))" "${SECOND_EXTRA_CMD[@]}" >"${SECOND_EXTRA_TEST_LOG}" 2>&1
		second_extra_test_exit=$?
	else
		"${SECOND_EXTRA_CMD[@]}" >"${SECOND_EXTRA_TEST_LOG}" 2>&1
		second_extra_test_exit=$?
	fi
	set -e

	{
		echo
		echo "[extra] ${SECOND_EXTRA_TEST_SCRIPT}"
		grep -E "PASS:|FAIL:|Night V3 objective pack smoke" "${SECOND_EXTRA_TEST_LOG}" | tail -n 160 || true
	} >>"${SUMMARY_LOG}"
	echo "[headless] extra summary:"
	grep -E "PASS:|FAIL:|Night V3 objective pack smoke" "${SECOND_EXTRA_TEST_LOG}" | tail -n 160 || true

	echo "[headless] extra log: ${SECOND_EXTRA_TEST_LOG}"

	if [[ ${second_extra_test_exit} -ne 0 ]]; then
		echo "[headless] extra script exited with code ${second_extra_test_exit}" >&2
		tail -n 160 "${SECOND_EXTRA_TEST_LOG}" || true
		exit ${second_extra_test_exit}
	fi

	if ! grep -q "${SECOND_EXTRA_TEST_PASS_MARKER}" "${SECOND_EXTRA_TEST_LOG}"; then
		echo "[headless] extra script did not report success marker" >&2
		tail -n 160 "${SECOND_EXTRA_TEST_LOG}" || true
		exit 1
	fi

	if [[ -n "${ALLOW_ENGINE_FAILURE_REGEX}" ]]; then
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${SECOND_EXTRA_TEST_LOG}" | grep -Ev "${ALLOW_ENGINE_FAILURE_REGEX}" || true)"
	else
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${SECOND_EXTRA_TEST_LOG}" || true)"
	fi
	if [[ -n "${engine_failures}" ]]; then
		echo "[headless] engine/runtime failures detected in extra test log" >&2
		echo "${engine_failures}" | head -n 120 >&2
		exit 1
	fi
fi

if [[ -n "${THIRD_EXTRA_TEST_SCRIPT}" ]]; then
	echo "[headless] run extra script=${THIRD_EXTRA_TEST_SCRIPT} quit_after=${QUIT_AFTER}"
	THIRD_EXTRA_CMD=("${GODOT_BIN}" --headless --path "${ROOT_DIR}" -s "${THIRD_EXTRA_TEST_SCRIPT}" --quit-after "${QUIT_AFTER}")
	set +e
	if command -v timeout >/dev/null 2>&1; then
		timeout --preserve-status "$((QUIT_AFTER + 120))" "${THIRD_EXTRA_CMD[@]}" >"${THIRD_EXTRA_TEST_LOG}" 2>&1
		third_extra_test_exit=$?
	else
		"${THIRD_EXTRA_CMD[@]}" >"${THIRD_EXTRA_TEST_LOG}" 2>&1
		third_extra_test_exit=$?
	fi
	set -e

	{
		echo
		echo "[extra] ${THIRD_EXTRA_TEST_SCRIPT}"
		grep -E "PASS:|FAIL:|Night destroy-nodes smoke" "${THIRD_EXTRA_TEST_LOG}" | tail -n 160 || true
	} >>"${SUMMARY_LOG}"
	echo "[headless] extra summary:"
	grep -E "PASS:|FAIL:|Night destroy-nodes smoke" "${THIRD_EXTRA_TEST_LOG}" | tail -n 160 || true

	echo "[headless] extra log: ${THIRD_EXTRA_TEST_LOG}"

	if [[ ${third_extra_test_exit} -ne 0 ]]; then
		echo "[headless] extra script exited with code ${third_extra_test_exit}" >&2
		tail -n 160 "${THIRD_EXTRA_TEST_LOG}" || true
		exit ${third_extra_test_exit}
	fi

	if ! grep -q "${THIRD_EXTRA_TEST_PASS_MARKER}" "${THIRD_EXTRA_TEST_LOG}"; then
		echo "[headless] extra script did not report success marker" >&2
		tail -n 160 "${THIRD_EXTRA_TEST_LOG}" || true
		exit 1
	fi

	if [[ -n "${ALLOW_ENGINE_FAILURE_REGEX}" ]]; then
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${THIRD_EXTRA_TEST_LOG}" | grep -Ev "${ALLOW_ENGINE_FAILURE_REGEX}" || true)"
	else
		engine_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${THIRD_EXTRA_TEST_LOG}" || true)"
	fi
	if [[ -n "${engine_failures}" ]]; then
		echo "[headless] engine/runtime failures detected in extra test log" >&2
		echo "${engine_failures}" | head -n 120 >&2
		exit 1
	fi
fi

echo "[headless] PASS"
