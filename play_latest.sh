#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BRANCH="${PLAY_LATEST_BRANCH:-main}"
GODOT_BIN="${GODOT_BIN:-godot}"
START_SCENE="${PLAY_LATEST_SCENE:-res://scenes/meta/MetaLoopRoot.tscn}"
UPDATE_ENABLED=1
ALLOW_DIRTY=0

print_usage() {
  cat <<USAGE
Usage: ./play_latest.sh [options]

Options:
  --no-update         Skip git update and just launch the game.
  --allow-dirty       Allow launch/update attempt even if working tree is dirty.
  --branch <name>     Branch to update from (default: main, or PLAY_LATEST_BRANCH).
  --godot <path>      Godot executable (default: godot, or GODOT_BIN).
  --scene <path>      Scene to launch (default: res://scenes/meta/MetaLoopRoot.tscn).
  -h, --help          Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-update)
      UPDATE_ENABLED=0
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      shift
      ;;
    --branch)
      TARGET_BRANCH="${2:-}"
      if [[ -z "$TARGET_BRANCH" ]]; then
        echo "[play_latest] missing value for --branch" >&2
        exit 2
      fi
      shift 2
      ;;
    --godot)
      GODOT_BIN="${2:-}"
      if [[ -z "$GODOT_BIN" ]]; then
        echo "[play_latest] missing value for --godot" >&2
        exit 2
      fi
      shift 2
      ;;
    --scene)
      START_SCENE="${2:-}"
      if [[ -z "$START_SCENE" ]]; then
        echo "[play_latest] missing value for --scene" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "[play_latest] unknown option: $1" >&2
      print_usage
      exit 2
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "[play_latest] git not found in PATH" >&2
  exit 127
fi

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "[play_latest] Godot executable not found: $GODOT_BIN" >&2
  echo "[play_latest] set GODOT_BIN=/path/to/godot or pass --godot /path/to/godot" >&2
  exit 127
fi

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[play_latest] not inside a git repository: $ROOT_DIR" >&2
  exit 2
fi

scene_file="$START_SCENE"
if [[ "$START_SCENE" == res://* ]]; then
  scene_file="$ROOT_DIR/${START_SCENE#res://}"
fi

if [[ ! -f "$scene_file" ]]; then
  echo "[play_latest] scene not found: $START_SCENE" >&2
  exit 2
fi

is_dirty=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  is_dirty=1
fi

if [[ "$is_dirty" -eq 1 && "$ALLOW_DIRTY" -eq 0 ]]; then
  echo "[play_latest] working tree has uncommitted changes." >&2
  echo "[play_latest] commit/stash first, or run with --allow-dirty to continue." >&2
  exit 2
fi

if [[ "$UPDATE_ENABLED" -eq 1 ]]; then
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" != "$TARGET_BRANCH" ]]; then
    echo "[play_latest] switching branch: $current_branch -> $TARGET_BRANCH"
    git checkout "$TARGET_BRANCH"
  fi

  echo "[play_latest] fetching origin/$TARGET_BRANCH"
  git fetch origin "$TARGET_BRANCH" --prune

  echo "[play_latest] pulling latest (fast-forward only)"
  git pull --ff-only origin "$TARGET_BRANCH"
fi

echo "[play_latest] launching scene: $START_SCENE"
exec "$GODOT_BIN" --path "$ROOT_DIR" "$START_SCENE"
