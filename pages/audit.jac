sv import from "main" { get_audit_summary }
import from "..components.ui.button" { Button }
import from "..components.ui.spinner" { Spinner }

def:pub AuditReport() -> JsxPage {
    has audit_summary: str = "";
    has audit_loading: bool = False;
    has error_msg: str = "";

    async def load_audit() -> None {
        audit_loading = True;
        error_msg = "";
        try {
            result: dict = await get_audit_summary();
            audit_summary = result["summary"] as str;
        } except Exception as e {
            error_msg = "Failed to load audit: " + str(e);
        }
        audit_loading = False;
    }

    async can with entry {
        await load_audit();
    }

    return <main className="max-w-5xl mx-auto px-4 py-6 flex flex-col gap-6">
        <div className="flex items-center justify-between gap-2">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider">
                Audit Report
            </h2>
            <Button variant="outline" size="sm" onClick={lambda (e: MouseEvent) { load_audit(); }} disabled={audit_loading}>
                {"Generating..." if audit_loading else "Regenerate"}
            </Button>
        </div>

        {if len(error_msg) > 0 {
            <div className="rounded-lg border border-destructive/30 bg-destructive/5 p-3">
                <p className="text-sm text-destructive">{error_msg}</p>
            </div>
        }}

        {if audit_loading and len(audit_summary) == 0 {
            <div className="rounded-lg border border-border bg-card p-4 flex items-center gap-3">
                <Spinner className="size-4" />
                <span className="text-sm text-muted-foreground">Generating audit report...</span>
            </div>
        }}

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
    </main>;
}
