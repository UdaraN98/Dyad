#!/usr/bin/env bash
# PreToolUse hook for Claude Code: blocks git commands that write history or publish.
# Requires jq. Exit code 2 blocks the tool call and shows the message to Claude.

command=$(jq -r '.tool_input.command // ""')

if echo "$command" | grep -Eq 'git[^;|&]*[[:space:]](commit|push|merge|rebase|tag|cherry-pick|am)([[:space:]]|$)'; then
  echo "Blocked: this repo's rule is that Claude never commits or pushes. Leave changes uncommitted and tell the owner." >&2
  exit 2
fi

if echo "$command" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+(create|merge)'; then
  echo "Blocked: Claude does not create or merge pull requests in this repo." >&2
  exit 2
fi

exit 0
