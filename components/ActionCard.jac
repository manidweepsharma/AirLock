import from ".ui.card" { Card, CardHeader, CardTitle, CardContent }
import from ".ui.badge" { Badge }
import from ".ui.button" { Button }
import from "..lib.utils" { cn }

def risk_variant(risk: str) -> str {
    if risk == "DANGEROUS" {
        return "destructive";
    }
    if risk == "REVIEW" {
        return "outline";
    }
    return "secondary";
}

def risk_label(risk: str) -> str {
    if risk == "DANGEROUS" {
        return "DANGEROUS";
    }
    if risk == "REVIEW" {
        return "REVIEW";
    }
    if risk == "SAFE" {
        return "SAFE";
    }
    return "UNRATED";
}

def risk_border(risk: str) -> str {
    if risk == "DANGEROUS" {
        return "border-l-4 border-l-destructive bg-destructive/5";
    }
    if risk == "REVIEW" {
        return "border-l-4 border-l-yellow-500 bg-yellow-500/5";
    }
    if risk == "SAFE" {
        return "border-l-4 border-l-green-500 bg-green-500/5";
    }
    return "border-l-4 border-l-muted";
}

def type_icon(action_type: str) -> str {
    if action_type == "file_edit" {
        return "FILE";
    }
    if action_type == "shell_cmd" {
        return "SHELL";
    }
    if action_type == "db_mutation" {
        return "DB";
    }
    if action_type == "api_call" {
        return "API";
    }
    return "ACT";
}

def:pub ActionCard(
    action_id: str,
    action_type: str,
    detail: str,
    risk: str,
    explanation: str,
    timestamp: str,
    approved: bool,
    override_flag: bool,
    onApprove: Callable[[str, bool], None],
    rejected: bool = False,
    onReject: Callable[[str], None] | None = None,
    url: str = "",
    verified: bool = False,
    claimed_risk: str = "",
    verified_risk: str = "",
    scraped_excerpt: str = ""
) -> JsxElement {
    has approving: bool = False;
    has rejecting: bool = False;

    async def handle_approve(use_override: bool) -> None {
        approving = True;
        onApprove(action_id, use_override);
        approving = False;
    }

    async def handle_reject() -> None {
        rejecting = True;
        if onReject {
            onReject(action_id);
        }
        rejecting = False;
    }

    ts_short: str = timestamp[:19] if len(timestamp) >= 19 else timestamp;

    return <div className={cn("rounded-lg border bg-card p-4 flex flex-col gap-3 transition-all", risk_border(risk))}>
        <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-2 flex-wrap">
                <span className="text-xs font-mono font-semibold bg-muted px-2 py-0.5 rounded text-muted-foreground">
                    {type_icon(action_type)}
                </span>
                <span className="text-sm font-medium text-foreground">{action_type}</span>
                <Badge variant={risk_variant(risk)}>
                    {risk_label(risk)}
                </Badge>
                {if approved {
                    <Badge variant="secondary" className={cn("text-xs", "bg-green-500/15 text-green-700 border-green-500/30" if not override_flag else "bg-orange-500/15 text-orange-700 border-orange-500/30")}>
                        {"APPROVED" if not override_flag else "OVERRIDE"}
                    </Badge>
                }}
                {if rejected {
                    <Badge variant="secondary" className="text-xs bg-red-500/15 text-red-700 border-red-500/30">
                        REJECTED
                    </Badge>
                }}
                {if verified {
                    <Badge variant="secondary" className="text-xs bg-blue-500/15 text-blue-700 border-blue-500/30">
                        Verified via Firecrawl
                    </Badge>
                }}
            </div>
            <span className="text-xs text-muted-foreground shrink-0 font-mono">{ts_short}</span>
        </div>

        <p className="text-sm text-foreground font-mono bg-muted/50 rounded px-3 py-2 break-all">
            {detail}
        </p>

        {if len(url) > 0 {
            <p className="text-xs text-muted-foreground font-mono break-all">{url}</p>
        }}

        {if verified and len(claimed_risk) > 0 and len(verified_risk) > 0 and claimed_risk != verified_risk {
            <div className="rounded border border-blue-500/30 bg-blue-500/5 px-3 py-2 flex flex-col gap-1">
                <p className="text-xs font-semibold text-blue-700">
                    Agent's self-report said {claimed_risk} — Firecrawl's independent re-fetch found {verified_risk}
                </p>
                {if len(scraped_excerpt) > 0 {
                    <p className="text-xs text-muted-foreground font-mono break-all line-clamp-4">{scraped_excerpt}</p>
                }}
            </div>
        }}

        {if len(explanation) > 0 {
            <p className="text-xs text-muted-foreground italic">{explanation}</p>
        }}

        {if risk == "DANGEROUS" and not approved and not rejected {
            <div className="flex items-center gap-2 pt-1 border-t border-border">
                <div className="flex-1">
                    <p className="text-xs font-semibold text-destructive">Action blocked — human review required</p>
                </div>
                <Button
                    variant="outline"
                    size="sm"
                    onClick={lambda (e: MouseEvent) { handle_reject(); }}
                    disabled={rejecting}
                >
                    {"Rejecting..." if rejecting else "Reject"}
                </Button>
                <Button
                    variant="destructive"
                    size="sm"
                    onClick={lambda (e: MouseEvent) { handle_approve(True); }}
                    disabled={approving}
                >
                    {"Overriding..." if approving else "Override + Approve"}
                </Button>
            </div>
        }}
        {if risk == "REVIEW" and not approved and not rejected {
            <div className="flex items-center gap-2 pt-1 border-t border-border">
                <div className="flex-1">
                    <p className="text-xs font-semibold text-yellow-600">Needs review before proceeding</p>
                </div>
                <Button
                    variant="outline"
                    size="sm"
                    onClick={lambda (e: MouseEvent) { handle_reject(); }}
                    disabled={rejecting}
                >
                    {"Rejecting..." if rejecting else "Reject"}
                </Button>
                <Button
                    variant="outline"
                    size="sm"
                    onClick={lambda (e: MouseEvent) { handle_approve(True); }}
                    disabled={approving}
                >
                    {"Approving..." if approving else "Approve"}
                </Button>
            </div>
        }}
        {if risk == "SAFE" and not approved {
            <div className="flex items-center gap-2 pt-1 border-t border-border">
                <Button
                    variant="secondary"
                    size="sm"
                    onClick={lambda (e: MouseEvent) { handle_approve(False); }}
                    disabled={approving}
                >
                    {"Approving..." if approving else "Approve"}
                </Button>
            </div>
        }}
    </div>;
}
