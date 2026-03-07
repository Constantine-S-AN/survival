#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_RUNNER="${ROOT_DIR}/scripts/ci/run_headless_tests.sh"
SUITE="${SIM_SUITE:-all}"
PASS_ARGS=()

for arg in "$@"; do
	case "$arg" in
		--suite=*)
			SUITE="${arg#--suite=}"
			;;
		--skip-import)
			PASS_ARGS+=("$arg")
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 2
			;;
	esac
done

TEST_SCENE="res://tests/SimulationRunner.tscn" "${BASE_RUNNER}" "${PASS_ARGS[@]}" "--suite=${SUITE}"
