sv import from "main" { list_actions, approve, reject, run_demo }
import from "..components.ActionCard" { ActionCard }
import from "..components.ui.button" { Button }
import from "..components.ui.spinner" { Spinner }
import from "..components.ui.input" { Input }

def:pub ActionFeed() -> JsxPage {
    has actions: list[dict] = [];
    has loading: bool = True;
    has error_msg: str = "";
    has safe_count: int = 0;
    has review_count: int = 0;
    has dangerous_count: int = 0;
    has demo_running: bool = False;
    has reviewer_name: str = "";

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
            root spawn approve(action_id=action_id, human_override=use_override, reviewer=reviewer_name);
            await refresh();
        } except Exception as e {
            error_msg = "Approve failed: " + str(e);
        }
    }

    async def handle_reject(action_id: str) -> None {
        try {
            root spawn reject(action_id=action_id, reviewer=reviewer_name);
            await refresh();
        } except Exception as e {
            error_msg = "Reject failed: " + str(e);
        }
    }

    def handle_reviewer_change(e: ChangeEvent) {
        reviewer_name = e.target.value;
    }

    async def handle_run_demo() -> None {
        demo_running = True;
        error_msg = "";
        try {
            await run_demo();
            await refresh();
        } except Exception as e {
            error_msg = "Demo run failed: " + str(e);
        }
        demo_running = False;
    }

    return <main className="max-w-5xl mx-auto px-4 py-6 flex flex-col gap-6">

        {#* Toolbar *#}
        <div className="flex items-center justify-between gap-2 flex-wrap">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
                {"Action Feed — " + str(len(actions)) + " recorded"}
            </h2>
            <div className="flex items-center gap-2">
                <Input
                    placeholder="Your name"
                    value={reviewer_name}
                    onChange={handle_reviewer_change}
                    className="h-8 w-32 text-xs"
                />
                <Button variant="outline" size="sm" onClick={lambda (e: MouseEvent) { refresh(); }}>
                    Refresh
                </Button>
                <Button variant="default" size="sm" onClick={lambda (e: MouseEvent) { handle_run_demo(); }} disabled={demo_running}>
                    {"Running demo..." if demo_running else "Run Demo Agent"}
                </Button>
            </div>
        </div>

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

        {#* Error *#}
        {if len(error_msg) > 0 {
            <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-3">
                <p className="text-sm text-destructive">{error_msg}</p>
            </div>
        }}

        {#* Action feed *#}
        <div className="flex flex-col gap-3">
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
                    <Button variant="default" size="sm" className="mt-1" onClick={lambda (e: MouseEvent) { handle_run_demo(); }} disabled={demo_running}>
                        {"Running demo..." if demo_running else "Run Demo Agent"}
                    </Button>
                    <p className="text-xs text-muted-foreground">or from the CLI:</p>
                    <div className="rounded bg-muted px-3 py-2 font-mono text-xs text-muted-foreground">
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
                                rejected={a["rejected"] as bool}
                                reviewer={a["reviewer"] as str}
                                onApprove={handle_approve}
                                onReject={handle_reject}
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
    </main>;
}
