cl import ".styles.global.css";

sv import from "main" { list_actions, get_audit_summary }
import from ".components.ActionCard" { ActionCard }
import from ".components.ui.button" { Button }
import from ".components.ui.badge" { Badge }
import from ".components.ui.spinner" { Spinner }
import from ".components.ui.separator" { Separator }
import from ".components.ui.scroll_area" { ScrollArea }
import from "@jac/runtime" { jacSpawn }

def:pub AirlockApp() -> JsxElement {
    has actions: list[dict] = [];
    has loading: bool = True;
    has audit_summary: str = "";
    has audit_loading: bool = False;
    has error_msg: str = "";
    has safe_count: int = 0;
    has review_count: int = 0;
    has dangerous_count: int = 0;
    has polling: bool = True;

    async can with entry {
        loading = True;
        try {
            data: list[dict] = await list_actions();
            actions = data;
            safe_count = len([a for a in data if a["risk"] == "SAFE"]);
            review_count = len([a for a in data if a["risk"] == "REVIEW"]);
            dangerous_count = len([a for a in data if a["risk"] == "DANGEROUS"]);
        } except Exception as e {
            error_msg = "Failed to load actions: " + str(e);
        }
        loading = False;
    }

    async def refresh() -> None {
        try {
            data: list[dict] = await list_actions();
            actions = data;
            safe_count = len([a for a in data if a["risk"] == "SAFE"]);
            review_count = len([a for a in data if a["risk"] == "REVIEW"]);
            dangerous_count = len([a for a in data if a["risk"] == "DANGEROUS"]);
            error_msg = "";
        } except Exception as e {
            error_msg = "Refresh failed: " + str(e);
        }
    }

    async def handle_approve(action_id: str, use_override: bool) -> None {
        try {
            payload: any = {"action_id": action_id, "human_override": use_override};
            result: any = await jacSpawn("approve", payload);
            await refresh();
        } except Exception as e {
            error_msg = "Approve failed: " + str(e);
        }
    }

    async def load_audit() -> None {
        audit_loading = True;
        try {
            result: dict = await get_audit_summary();
            audit_summary = result["summary"] as str;
        } except Exception as e {
            audit_summary = "Failed to load audit: " + str(e);
        }
        audit_loading = False;
    }

    return <div className="min-h-screen bg-background text-foreground">
        {#* Header *#}
        <header className="border-b border-border bg-card/80 backdrop-blur-sm sticky top-0 z-10">
            <div className="max-w-5xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                    <div className="size-8 rounded-lg bg-destructive flex items-center justify-center">
                        <span className="text-destructive-foreground text-xs font-bold">AL</span>
                    </div>
                    <div>
                        <h1 className="text-base font-bold tracking-tight">Airlock</h1>
                        <p className="text-xs text-muted-foreground">AI Agent Safety Sandbox</p>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <Button variant="outline" size="sm" onClick={lambda (e: MouseEvent) { refresh(); }}>
                        Refresh
                    </Button>
                    <Button variant="secondary" size="sm" onClick={lambda (e: MouseEvent) { load_audit(); }}>
                        Audit Report
                    </Button>
                </div>
            </div>
        </header>

        <main className="max-w-5xl mx-auto px-4 py-6 flex flex-col gap-6">

            {#* Stats bar *#}
            <div className="grid grid-cols-3 gap-3">
                <div className="rounded-lg border border-green-500/30 bg-green-500/5 p-3 flex flex-col gap-1">
                    <span className="text-2xl font-bold text-green-600">{str(safe_count)}</span>
                    <span className="text-xs text-muted-foreground font-medium">Safe Actions</span>
                </div>
                <div className="rounded-lg border border-yellow-500/30 bg-yellow-500/5 p-3 flex flex-col gap-1">
                    <span className="text-2xl font-bold text-yellow-600">{str(review_count)}</span>
                    <span className="text-xs text-muted-foreground font-medium">Needs Review</span>
                </div>
                <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-3 flex flex-col gap-1">
                    <span className="text-2xl font-bold text-destructive">{str(dangerous_count)}</span>
                    <span className="text-xs text-muted-foreground font-medium">Dangerous</span>
                </div>
            </div>

            {#* Audit summary *#}
            {if len(audit_summary) > 0 {
                <div className="rounded-lg border border-border bg-card p-4 flex flex-col gap-2">
                    <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold">Audit Summary</span>
                        {if audit_loading {
                            <Spinner className="size-3" />
                        }}
                    </div>
                    <p className="text-sm text-muted-foreground leading-relaxed">{audit_summary}</p>
                </div>
            }}
            {if audit_loading and len(audit_summary) == 0 {
                <div className="rounded-lg border border-border bg-card p-4 flex items-center gap-3">
                    <Spinner className="size-4" />
                    <span className="text-sm text-muted-foreground">Generating audit report...</span>
                </div>
            }}

            {#* Error *#}
            {if len(error_msg) > 0 {
                <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-3">
                    <p className="text-sm text-destructive">{error_msg}</p>
                </div>
            }}

            {#* Action feed *#}
            <div className="flex flex-col gap-3">
                <div className="flex items-center justify-between">
                    <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
                        {"Action Feed — " + str(len(actions)) + " recorded"}
                    </h2>
                </div>

                {if loading {
                    <div className="flex items-center justify-center py-16">
                        <div className="flex flex-col items-center gap-3">
                            <Spinner className="size-6" />
                            <p className="text-sm text-muted-foreground">Loading actions...</p>
                        </div>
                    </div>
                }}

                {if not loading and len(actions) == 0 {
                    <div className="rounded-lg border border-dashed border-border p-12 flex flex-col items-center gap-3 text-center">
                        <div className="size-12 rounded-full bg-muted flex items-center justify-center">
                            <span className="text-muted-foreground text-lg font-bold">0</span>
                        </div>
                        <p className="text-sm font-medium">No actions recorded yet</p>
                        <p className="text-xs text-muted-foreground max-w-xs">
                            Run the demo agent to see actions stream in with real-time risk classification.
                        </p>
                        <div className="mt-2 rounded bg-muted px-3 py-2 font-mono text-xs text-muted-foreground">
                            jac run demo_agent.jac
                        </div>
                    </div>
                }}

                {if not loading and len(actions) > 0 {
                    <div className="flex flex-col gap-3">
                        {for a in actions {
                            if a is not None {
                                <ActionCard
                                    action_id={a["id"] as str}
                                    action_type={a["action_type"] as str}
                                    detail={a["detail"] as str}
                                    risk={a["risk"] as str}
                                    explanation={a["explanation"] as str}
                                    timestamp={a["timestamp"] as str}
                                    approved={a["approved"] as bool}
                                    override_flag={a["override"] as bool}
                                    onApprove={handle_approve}
                                    url={a["url"] as str}
                                    verified={a["verified"] as bool}
                                    claimed_risk={a["claimed_risk"] as str}
                                    verified_risk={a["verified_risk"] as str}
                                    scraped_excerpt={a["scraped_excerpt"] as str}
                                />
                            }
                        }}
                    </div>
                }}
            </div>

            {#* Footer *#}
            <div className="pt-4 border-t border-border">
                <p className="text-xs text-muted-foreground text-center">
                    Airlock — JacHacks SF 2026 — Built with Jac graph + walker + byLLM
                </p>
            </div>
        </main>
    </div>;
}
