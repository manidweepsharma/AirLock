#!/usr/bin/env python3
"""PostToolUse hook: mirror this session's real tool calls into the Airlock
dashboard (POST /walker/log_action), the same endpoint demo_agent.jac uses.
Fails silently and fast if the Airlock dev server isn't running - never
blocks the real Claude Code session."""

import json
import sys
import urllib.request
import urllib.error

AIRLOCK_URL = "http://localhost:8000/walker/log_action"


def build_action(payload):
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    if tool_name == "Bash":
        command = tool_input.get("command", "")
        return {"action_type": "shell_cmd", "detail": f"Ran shell command: {command}"}

    if tool_name in ("Edit", "Write", "NotebookEdit"):
        path = tool_input.get("file_path", "") or tool_input.get("notebook_path", "")
        return {"action_type": "file_edit", "detail": f"{tool_name} on {path}"}

    if tool_name == "WebFetch":
        url = tool_input.get("url", "")
        prompt = tool_input.get("prompt", "")
        return {
            "action_type": "web_fetch",
            "detail": f"Fetched {url} - {prompt}",
            "url": url,
        }

    return None


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return

    action = build_action(payload)
    if action is None:
        return

    body = json.dumps(action).encode("utf-8")
    req = urllib.request.Request(
        AIRLOCK_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        urllib.request.urlopen(req, timeout=25)
    except Exception:
        pass


if __name__ == "__main__":
    main()
