import from "@jac/runtime" { Outlet, Link, useLocation }

def:pub Shell() -> JsxLayout {
    location = useLocation();

    def nav_class(path: str) -> str {
        active: bool = location.pathname == path;
        return "text-sm font-medium px-3 py-1.5 rounded-md transition-colors " + (
            "bg-secondary text-secondary-foreground" if active else "text-muted-foreground hover:text-foreground"
        );
    }

    return <div className="min-h-screen bg-background text-foreground">
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
                <nav className="flex items-center gap-1">
                    <Link to="/" className={nav_class("/")}>Action Feed</Link>
                    <Link to="/audit" className={nav_class("/audit")}>Audit Report</Link>
                </nav>
            </div>
        </header>
        <Outlet />
    </div>;
}
