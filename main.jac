import from datetime { datetime }

# ─── Graph model ────────────────────────────────────────────────────────────

enum Risk: str {
    SAFE = "SAFE",
    REVIEW = "REVIEW",
    DANGEROUS = "DANGEROUS"
}

node Action {
    has action_type: str;
    has detail: str;
    has risk: str = "unrated";
    has explanation: str = "";
    has timestamp: str = "";
    has approved: bool = False;
    has override: bool = False;
}

edge FOLLOWS: Action --> Action {}

# ─── byLLM functions ────────────────────────────────────────────────────────

def classify_risk(action_type: str, detail: str) -> Risk by llm();
sem classify_risk = "You are a security auditor for an AI coding agent. Classify the risk level of the given action.";
sem classify_risk.action_type = "The type of action: file_edit, shell_cmd, db_mutation, api_call, or similar.";
sem classify_risk.detail = "A description of what the action does. Look for destructive operations like DROP TABLE, rm -rf, credential exposure, or irreversible changes.";

def explain_action(action_type: str, detail: str, risk: str) -> str by llm();
sem explain_action = "You are a security auditor. Write a single concise sentence (max 15 words) explaining why this action has the given risk level.";
sem explain_action.action_type = "The type of action performed.";
sem explain_action.detail = "What the action does.";
sem explain_action.risk = "The risk classification: SAFE, REVIEW, or DANGEROUS.";

def synthesize_audit(actions_summary: str) -> str by llm();
sem synthesize_audit = "You are a security auditor reviewing an AI agent's session. Write a 3-5 sentence plain-language summary of what the agent did, highlighting any dangerous or suspicious actions and whether the session appears safe overall.";
sem synthesize_audit.actions_summary = "A newline-separated list of actions with their risk levels and details.";

# ─── Helper: get most recent Action from root ────────────────────────────────

def get_latest_action() -> Action | None {
    actions: list[Action] = [root -->[?:Action]];
    if len(actions) == 0 {
        return None;
    }
    # Walk the FOLLOWS chain to find the tail
    latest: Action = actions[0];
    for a in actions {
        followers: list[Action] = [a ->:FOLLOWS:->];
        if len(followers) == 0 {
            latest = a;
        }
    }
    return latest;
}

# ─── Walkers ────────────────────────────────────────────────────────────────

walker:pub log_action {
    has action_type: str = "";
    has detail: str = "";

    can run with Root entry {
        ts: str = datetime.now().isoformat();
        new_action: Action = Action(
            action_type=self.action_type,
            detail=self.detail,
            timestamp=ts
        );
        root ++> new_action;

        # Link to previous action via FOLLOWS edge
        prev: Action | None = get_latest_action();
        if prev is not None and jid(prev) != jid(new_action) {
            prev +>:FOLLOWS():+> new_action;
        }

        # Classify risk via LLM
        risk_val: Risk = classify_risk(self.action_type, self.detail);
        new_action.risk = risk_val.value;

        # Generate explanation via LLM
        expl: str = explain_action(self.action_type, self.detail, risk_val.value);
        new_action.explanation = expl;

        report {
            "id": jid(new_action),
            "action_type": new_action.action_type,
            "detail": new_action.detail,
            "risk": new_action.risk,
            "explanation": new_action.explanation,
            "timestamp": new_action.timestamp,
            "approved": new_action.approved,
            "override": new_action.override
        };
    }
}

walker:pub audit_report {
    has collected: list[str] = [];

    can gather with Root entry {
        visit [root -->[?:Action]];
    }

    can collect with Action entry {
        self.collected.append(
            f"[{here.risk}] {here.action_type}: {here.detail}"
        );
        visit [here ->:FOLLOWS:->];
    }

    can finish with Root exit {
        if len(self.collected) == 0 {
            report {"summary": "No actions recorded yet."};
            disengage;
        }
        summary_input: str = "\n".join(self.collected);
        summary: str = synthesize_audit(summary_input);
        report {"summary": summary, "action_count": len(self.collected)};
    }
}

walker:pub approve {
    has action_id: str = "";
    has human_override: bool = False;

    can run with Root entry {
        target: Action | None = None;
        for a in [root -->[?:Action]] {
            if jid(a) == self.action_id {
                target = a;
            }
        }
        if target is None {
            report {"approved": False, "error": "Action not found"};
            disengage;
        }
        act: Action = target as Action;
        if act.risk == "SAFE" {
            act.approved = True;
            report {"approved": True, "risk": act.risk, "override": False};
        } elif self.human_override {
            act.approved = True;
            act.override = True;
            report {"approved": True, "risk": act.risk, "override": True};
        } else {
            report {"approved": False, "risk": act.risk, "blocked": True};
        }
    }
}

def:pub list_actions() -> list[dict] {
    result: list[dict] = [];
    for a in [root -->[?:Action]] {
        result.append({
            "id": jid(a),
            "action_type": a.action_type,
            "detail": a.detail,
            "risk": a.risk,
            "explanation": a.explanation,
            "timestamp": a.timestamp,
            "approved": a.approved,
            "override": a.override
        });
    }
    return result;
}

def:pub get_audit_summary() -> dict {
    if len([root -->[?:Action]]) == 0 {
        return {"summary": "No actions recorded yet.", "action_count": 0};
    }
    collected: list[str] = [];
    for a in [root -->[?:Action]] {
        collected.append(f"[{a.risk}] {a.action_type}: {a.detail}");
    }
    summary_input: str = "\n".join(collected);
    summary: str = synthesize_audit(summary_input);
    return {"summary": summary, "action_count": len(collected)};
}

# ─── Client entry ────────────────────────────────────────────────────────────

cl import ".styles.global.css";
cl import from ".frontend" { AirlockApp }

def:pub app() -> JsxElement {
    return <AirlockApp />;
}
