"""
Smart Mobility KPI Dashboard — Open Source Template
=====================================================
Dashboard interattiva Plotly/Dash per la visualizzazione di KPI non finanziari
di progetti software complessi.

Versione: Open Source (dati anonimizzati/template)
Licenza: MIT
Autore: LEAF Mobility Team

Requisiti:
    pip install dash plotly pandas numpy

Avvio:
    python dashboard_kpi_opensource.py
    → Apri http://127.0.0.1:8050 nel browser

Adattamento:
    Modifica le sezioni "DATI DEL PROGETTO" con i valori del tuo progetto.
    Ogni struttura dati è documentata per facilitare la personalizzazione.
"""

import dash
from dash import dcc, html
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
import numpy as np

# ============================================================================
# CONFIGURAZIONE — Modifica qui per adattare al tuo progetto
# ============================================================================

PROJECT_NAME = "Smart Mobility Platform"
PROJECT_DATE = "2026-08-10"
PROJECT_AUTHOR = "Project Manager AI"

# ============================================================================
# DATI DEL PROGETTO — Sostituisci con i tuoi dati
# ============================================================================

# --- Spider Chart: Dimensioni su scala 0-10 ---
# Categorie del radar chart: aggiungi/rimuovi dimensioni a piacere
RADAR_CATEGORIES = [
    "Defect Density",       # Qualità del codice
    "First-Pass Rate",      # Efficienza procedurale
    "Test Coverage",        # Copertura test
    "Technical Debt",       # Debito tecnico (SQALE o equivalente)
    "Team Velocity",        # Velocità del team
    "Resource Util.",       # Utilizzo risorse
    "Team Diversity",       # Distribuzione contributi
    "Environmental",        # KPI ambientali
    "Social",               # KPI sociali
    "Governance",           # KPI di governance
    "Supply Chain",         # Robustezza supply chain
    "Risk Mgmt",            # Gestione rischi
]

# Punteggi 0-10 per ciascuna dimensione
RADAR_VALUES = [9, 8, 8, 9, 7, 5, 4, 10, 7, 9, 6, 7]

# Raggruppamento delle dimensioni per area
RADAR_GROUPS = {
    "Technical": [0, 1, 2, 3],     # indici delle dimensioni tecniche
    "Team": [4, 5, 6],             # indici delle dimensioni di team
    "ESG": [7, 8, 9, 10, 11],     # indici delle dimensioni ESG
}

# --- Sprint/Iteration Data ---
# Dati per il grafico Carico vs Qualità
SPRINT_DATA = pd.DataFrame({
    "Sprint": ["Iteration 1", "Iteration 2", "Iteration 3", "Post-release"],
    "Resource_Utilization": [40, 70, 95, 20],        # % di utilizzo risorse
    "Defect_Density": [0.0, 0.2, 0.58, 0.12],       # difetti per KLOC
    "Tasks_Per_Day": [0.8, 1.75, 2.56, 0.5],        # task completati al giorno
    "LOC": [8000, 16400, 17300, 17300],              # lines of code
    "Defects": [0, 3, 10, 1],                        # difetti trovati
    "Test_Count": [0, 0, 376, 376],                  # test totali
    "Active_Devs": [4, 4, 2, 1],                     # sviluppatori attivi
})

# --- Technical Debt Evolution ---
DEBT_HISTORY = pd.DataFrame({
    "Date": ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8", "W9"],
    "Debt_Ratio": [24.0, 20.0, 16.0, 15.0, 13.0, 8.0, 7.8, 7.8, 3.8],
    "Rating": ["D", "C", "C", "C", "C", "B", "B", "B", "A"],
    "Remediation_Hours": [84, 62, 51, 50, 42, 27, 27, 27, 13],
})

# --- Risk Register ---
RISK_DATA = pd.DataFrame({
    "Risk": [
        "R1: Credential exposure", "R2: Low test coverage",
        "R3: Tech debt above threshold", "R4: Integration errors",
        "R5: Deployment issues", "R6: Vendor lock-in",
        "R7: Team burnout", "R8: Compliance gap",
        "R9: Security vulnerability", "R10: CI/CD failure",
    ],
    "Realized": [100, 100, 100, 100, 100, 50, 50, 0, 0, 0],
    "Residual_Impact": [20, 0, 0, 0, 0, 40, 60, 0, 0, 0],
})

# --- Team Contribution Data ---
TEAM_DATA = pd.DataFrame({
    "Sprint": (["Iteration 1"] * 4) + (["Iteration 2"] * 4) + (["Iteration 3"] * 4),
    "Developer": ["Dev A", "Dev B", "Dev C", "Dev D"] * 3,
    "Contribution": [30, 25, 25, 20, 35, 25, 20, 20, 85, 10, 3, 2],
})

# --- CI/CD Gate Status ---
CICD_GATES = pd.DataFrame({
    "Gate": [
        "Linter", "Type Check", "Formatter", "Unit Tests",
        "Static Analysis", "Widget Tests", "Architecture",
        "Debt Check", "Mock Scan", "Security 1",
        "Security 2", "Security 3", "Security 4",
    ],
    "Status": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    "Type": ["CI"] * 9 + ["SEC"] * 4,
})


# ============================================================================
# TEMA — Personalizza colori e stile
# ============================================================================

COLORS = {
    "bg": "#0d1117",
    "card_bg": "#161b22",
    "text": "#e6edf3",
    "text_secondary": "#8b949e",
    "green": "#3fb950",
    "yellow": "#d29922",
    "orange": "#db6d28",
    "red": "#f85149",
    "blue": "#58a6ff",
    "purple": "#bc8cff",
    "teal": "#39d353",
    "accent": "#1f6feb",
    "grid": "#21262d",
}


# ============================================================================
# GRAFICI
# ============================================================================

app = dash.Dash(
    __name__,
    title=f"{PROJECT_NAME} — Non-Financial KPI Dashboard",
    meta_tags=[{"name": "viewport", "content": "width=device-width, initial-scale=1"}],
)


def _hex_to_rgba(hex_color: str, alpha: float) -> str:
    """Convert hex color to rgba string."""
    r, g, b = (int(hex_color.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    return f"rgba({r},{g},{b},{alpha})"


def create_radar_chart() -> go.Figure:
    """Spider/Radar Chart: Balance across Technical, Team, and ESG dimensions."""
    fig = go.Figure()

    fig.add_trace(go.Scatterpolar(
        r=RADAR_VALUES + [RADAR_VALUES[0]],
        theta=RADAR_CATEGORIES + [RADAR_CATEGORIES[0]],
        fill="toself",
        fillcolor=_hex_to_rgba(COLORS["blue"], 0.15),
        line=dict(color=COLORS["blue"], width=2),
        name="Overall Score",
        hovertemplate="%{theta}: %{r}/10<extra></extra>",
    ))

    group_colors = {"Technical": COLORS["teal"], "Team": COLORS["orange"], "ESG": COLORS["purple"]}
    for group_name, indices in RADAR_GROUPS.items():
        r_vals = [RADAR_VALUES[i] if i in indices else 0 for i in range(len(RADAR_CATEGORIES))]
        r_vals.append(r_vals[0])
        fig.add_trace(go.Scatterpolar(
            r=r_vals,
            theta=RADAR_CATEGORIES + [RADAR_CATEGORIES[0]],
            fill="toself",
            fillcolor=_hex_to_rgba(group_colors[group_name], 0.1),
            line=dict(color=group_colors[group_name], width=1.5, dash="dot"),
            name=group_name,
        ))

    fig.update_layout(
        polar=dict(
            bgcolor=COLORS["card_bg"],
            radialaxis=dict(visible=True, range=[0, 10], gridcolor=COLORS["grid"],
                            tickfont=dict(size=10, color=COLORS["text_secondary"])),
            angularaxis=dict(gridcolor=COLORS["grid"],
                             tickfont=dict(size=11, color=COLORS["text"])),
        ),
        showlegend=True,
        legend=dict(font=dict(color=COLORS["text"], size=11), bgcolor="rgba(0,0,0,0)",
                    x=0.02, y=-0.15, orientation="h"),
        paper_bgcolor=COLORS["card_bg"], font=dict(color=COLORS["text"]),
        title=dict(text="<b>🕸️ Radar — Technical / Team / ESG Balance</b>",
                   font=dict(size=16, color=COLORS["text"]), x=0.5),
        margin=dict(t=80, b=80, l=80, r=80), height=520,
    )
    return fig


def create_load_vs_quality_chart() -> go.Figure:
    """Scatter: Resource Utilization vs Defect Density with zone highlights."""
    fig = go.Figure()

    for x0, x1, y1, color, label in [
        (0, 60, 0.5, COLORS["green"], "GREEN ZONE"),
        (60, 85, 0.5, COLORS["yellow"], "YELLOW ZONE"),
        (85, 100, 1.0, COLORS["red"], "⚠️ RED ZONE"),
    ]:
        fig.add_shape(type="rect", x0=x0, x1=x1, y0=0, y1=y1,
                      fillcolor=_hex_to_rgba(color, 0.08), line=dict(width=0), layer="below")
        fig.add_annotation(x=(x0 + x1) / 2, y=y1 - 0.02, text=label, showarrow=False,
                           font=dict(size=10, color=color), opacity=0.5)

    sprint_colors = [COLORS["green"], COLORS["yellow"], COLORS["red"], COLORS["blue"]]
    for i, row in SPRINT_DATA.iterrows():
        fig.add_trace(go.Scatter(
            x=[row["Resource_Utilization"]], y=[row["Defect_Density"]],
            mode="markers+text",
            marker=dict(size=max(row["Defects"] * 4 + 15, 20),
                        color=sprint_colors[i], opacity=0.7,
                        line=dict(color=sprint_colors[i], width=2)),
            text=[row["Sprint"]], textposition="top center",
            textfont=dict(size=11, color=COLORS["text"]),
            name=row["Sprint"],
            hovertemplate=(
                f"<b>{row['Sprint']}</b><br>"
                f"Resource Utilization: {row['Resource_Utilization']}%<br>"
                f"Defect Density: {row['Defect_Density']}/KLOC<br>"
                f"Defects: {row['Defects']}<extra></extra>"
            ),
        ))

    # Quadratic trendline
    x_t = SPRINT_DATA["Resource_Utilization"].values.astype(float)
    y_t = SPRINT_DATA["Defect_Density"].values.astype(float)
    z = np.polyfit(x_t, y_t, 2)
    p = np.poly1d(z)
    x_s = np.linspace(15, 100, 100)
    fig.add_trace(go.Scatter(
        x=x_s, y=np.clip(p(x_s), 0, None), mode="lines",
        line=dict(color=COLORS["text_secondary"], width=1.5, dash="dash"),
        name="Trendline", hoverinfo="skip",
    ))

    fig.update_layout(
        xaxis=dict(title="Resource Capacity Utilization (%)", range=[10, 105],
                   gridcolor=COLORS["grid"], tickfont=dict(color=COLORS["text_secondary"])),
        yaxis=dict(title="Defect Density (defects/KLOC)", range=[-0.05, 1.0],
                   gridcolor=COLORS["grid"], tickfont=dict(color=COLORS["text_secondary"])),
        plot_bgcolor=COLORS["card_bg"], paper_bgcolor=COLORS["card_bg"],
        font=dict(color=COLORS["text"]),
        title=dict(text="<b>📊 Cognitive Load vs Quality — Resource Utilization ↔ Defect Density</b>",
                   font=dict(size=15, color=COLORS["text"]), x=0.5),
        showlegend=True,
        legend=dict(font=dict(color=COLORS["text"], size=10), bgcolor="rgba(0,0,0,0)",
                    x=0.02, y=-0.18, orientation="h"),
        margin=dict(t=80, b=80), height=500,
    )
    return fig


def create_debt_gauge() -> go.Figure:
    """Gauge + timeline: Technical Debt (SQALE) evolution."""
    fig = make_subplots(rows=1, cols=2, specs=[[{"type": "indicator"}, {"type": "xy"}]],
                        column_widths=[0.35, 0.65], horizontal_spacing=0.08)

    current_ratio = DEBT_HISTORY["Debt_Ratio"].iloc[-1]
    prev_ratio = DEBT_HISTORY["Debt_Ratio"].iloc[-2]
    current_rating = DEBT_HISTORY["Rating"].iloc[-1]

    fig.add_trace(go.Indicator(
        mode="gauge+number+delta",
        value=current_ratio,
        delta={"reference": prev_ratio, "decreasing": {"color": COLORS["green"]}},
        number={"suffix": "%", "font": {"size": 36, "color": COLORS["text"]}},
        title={"text": f"Rating: {current_rating}", "font": {"size": 14, "color": COLORS["teal"]}},
        gauge=dict(
            axis=dict(range=[0, 30], tickwidth=1, tickcolor=COLORS["text_secondary"]),
            bar=dict(color=COLORS["teal"]), bgcolor=COLORS["card_bg"], borderwidth=0,
            steps=[
                {"range": [0, 5], "color": _hex_to_rgba(COLORS["green"], 0.2)},
                {"range": [5, 10], "color": _hex_to_rgba(COLORS["blue"], 0.2)},
                {"range": [10, 20], "color": _hex_to_rgba(COLORS["yellow"], 0.2)},
                {"range": [20, 50], "color": _hex_to_rgba(COLORS["red"], 0.2)},
            ],
            threshold=dict(line=dict(color=COLORS["red"], width=3), thickness=0.75, value=20),
        ),
    ), row=1, col=1)

    rating_colors = {"A": COLORS["teal"], "B": COLORS["blue"], "C": COLORS["yellow"], "D": COLORS["red"]}
    fig.add_trace(go.Scatter(
        x=DEBT_HISTORY["Date"], y=DEBT_HISTORY["Debt_Ratio"],
        mode="lines+markers",
        line=dict(color=COLORS["blue"], width=2.5),
        marker=dict(size=10,
                    color=[rating_colors.get(r, COLORS["text"]) for r in DEBT_HISTORY["Rating"]],
                    line=dict(color=COLORS["text"], width=1)),
        name="Debt Ratio %",
    ), row=1, col=2)

    fig.add_hline(y=20, line_dash="dot", line_color=COLORS["red"],
                  annotation_text="⚠️ Alarm threshold (20%)",
                  annotation_font=dict(size=10, color=COLORS["red"]), row=1, col=2)

    fig.update_xaxes(tickfont=dict(size=9, color=COLORS["text_secondary"]),
                     gridcolor=COLORS["grid"], row=1, col=2)
    fig.update_yaxes(title_text="Debt Ratio %", range=[0, 28], gridcolor=COLORS["grid"],
                     tickfont=dict(color=COLORS["text_secondary"]), row=1, col=2)

    fig.update_layout(
        paper_bgcolor=COLORS["card_bg"], plot_bgcolor=COLORS["card_bg"],
        font=dict(color=COLORS["text"]),
        title=dict(text="<b>📉 Technical Debt — SQALE Evolution</b>",
                   font=dict(size=15, color=COLORS["text"]), x=0.5),
        showlegend=False, margin=dict(t=80, b=50), height=380,
    )
    return fig


def create_risk_chart() -> go.Figure:
    """Horizontal bar: Risk Realized Percentage."""
    fig = go.Figure()

    fig.add_trace(go.Bar(
        y=RISK_DATA["Risk"], x=RISK_DATA["Realized"], orientation="h",
        name="Realized (%)",
        marker=dict(color=[
            COLORS["red"] if v == 100 else COLORS["yellow"] if v == 50 else COLORS["green"]
            for v in RISK_DATA["Realized"]
        ], opacity=0.7),
    ))
    fig.add_trace(go.Bar(
        y=RISK_DATA["Risk"], x=RISK_DATA["Residual_Impact"], orientation="h",
        name="Residual Impact (%)",
        marker=dict(color=COLORS["purple"], opacity=0.5, pattern=dict(shape="/")),
    ))

    rrp = RISK_DATA["Realized"].mean()
    fig.add_annotation(x=80, y=-0.5, text=f"<b>Risk Realized: {rrp:.0f}%</b>",
                       showarrow=False, font=dict(size=13, color=COLORS["yellow"]),
                       bgcolor=_hex_to_rgba(COLORS["yellow"], 0.15),
                       bordercolor=COLORS["yellow"], borderwidth=1, borderpad=6)

    fig.update_layout(
        barmode="overlay",
        xaxis=dict(title="Percentage (%)", range=[0, 110], gridcolor=COLORS["grid"],
                   tickfont=dict(color=COLORS["text_secondary"])),
        yaxis=dict(tickfont=dict(size=10, color=COLORS["text"]), autorange="reversed"),
        plot_bgcolor=COLORS["card_bg"], paper_bgcolor=COLORS["card_bg"],
        font=dict(color=COLORS["text"]),
        title=dict(text="<b>⚡ Risk Realized — Materialized vs Residual Impact</b>",
                   font=dict(size=15, color=COLORS["text"]), x=0.5),
        legend=dict(font=dict(color=COLORS["text"], size=10), bgcolor="rgba(0,0,0,0)",
                    orientation="h", x=0.3, y=-0.15),
        margin=dict(t=80, b=60, l=200), height=420,
    )
    return fig


def create_team_diversity_chart() -> go.Figure:
    """Stacked bar: Team contribution distribution (ESG Diversity)."""
    dev_colors = {"Dev A": COLORS["blue"], "Dev B": COLORS["teal"],
                  "Dev C": COLORS["purple"], "Dev D": COLORS["orange"]}

    fig = go.Figure()
    for dev in dev_colors:
        dd = TEAM_DATA[TEAM_DATA["Developer"] == dev]
        fig.add_trace(go.Bar(
            x=dd["Sprint"], y=dd["Contribution"], name=dev,
            marker=dict(color=dev_colors[dev], opacity=0.8),
            text=[f"{v}%" for v in dd["Contribution"]], textposition="inside",
            textfont=dict(size=11, color="white"),
        ))

    fig.update_layout(
        barmode="stack",
        xaxis=dict(tickfont=dict(color=COLORS["text"])),
        yaxis=dict(title="Contribution (%)", range=[0, 105], gridcolor=COLORS["grid"],
                   tickfont=dict(color=COLORS["text_secondary"])),
        plot_bgcolor=COLORS["card_bg"], paper_bgcolor=COLORS["card_bg"],
        font=dict(color=COLORS["text"]),
        title=dict(text="<b>👥 ESG Diversity — Team Contribution per Sprint</b>",
                   font=dict(size=15, color=COLORS["text"]), x=0.5),
        legend=dict(font=dict(color=COLORS["text"], size=11), bgcolor="rgba(0,0,0,0)",
                    orientation="h", x=0.15, y=-0.15),
        margin=dict(t=80, b=60), height=380,
    )
    return fig


def create_cicd_heatmap() -> go.Figure:
    """CI/CD Gate Status heatmap."""
    fig = go.Figure(go.Heatmap(
        z=[[s for s in CICD_GATES["Status"]]],
        x=CICD_GATES["Gate"], y=["Current"],
        colorscale=[[0, COLORS["red"]], [1, COLORS["green"]]],
        showscale=False,
        text=[["✅" if s else "❌" for s in CICD_GATES["Status"]]],
        texttemplate="%{text}", textfont=dict(size=16),
    ))

    n_green = sum(CICD_GATES["Status"])
    n_total = len(CICD_GATES)
    fig.update_layout(
        xaxis=dict(tickfont=dict(size=9, color=COLORS["text"]), tickangle=-45),
        yaxis=dict(tickfont=dict(color=COLORS["text"])),
        plot_bgcolor=COLORS["card_bg"], paper_bgcolor=COLORS["card_bg"],
        font=dict(color=COLORS["text"]),
        title=dict(text=f"<b>🟢 CI/CD & Security Gates — {n_green}/{n_total} GREEN</b>",
                   font=dict(size=15, color=COLORS["text"]), x=0.5),
        margin=dict(t=80, b=100, l=100), height=200,
    )
    return fig


def create_kpi_cards() -> list:
    """Top-level KPI summary cards."""
    cards_info = [
        {"label": "Debt Rating", "value": str(DEBT_HISTORY["Rating"].iloc[-1]),
         "sub": f"{DEBT_HISTORY['Debt_Ratio'].iloc[-1]}% debt ratio",
         "color": COLORS["teal"], "icon": "🏆"},
        {"label": "Defect Density", "value": f"{SPRINT_DATA['Defect_Density'].mean():.2f}",
         "sub": "avg defects/KLOC", "color": COLORS["green"], "icon": "🐛"},
        {"label": "First-Pass Rate", "value": "87%",
         "sub": "gates passed 1st try", "color": COLORS["blue"], "icon": "✅"},
        {"label": "Total Tests", "value": str(SPRINT_DATA["Test_Count"].max()),
         "sub": "automated tests", "color": COLORS["purple"], "icon": "🧪"},
        {"label": "Risk Realized", "value": f"{RISK_DATA['Realized'].mean():.0f}%",
         "sub": "of identified risks", "color": COLORS["yellow"], "icon": "⚡"},
    ]

    cards = []
    for c in cards_info:
        cards.append(html.Div([
            html.Div(c["icon"], style={"fontSize": "28px", "marginBottom": "4px"}),
            html.Div(c["value"], style={"fontSize": "32px", "fontWeight": "700",
                                        "color": c["color"], "lineHeight": "1.1"}),
            html.Div(c["label"], style={"fontSize": "12px", "color": COLORS["text"],
                                         "fontWeight": "600", "marginTop": "2px",
                                         "textTransform": "uppercase", "letterSpacing": "0.5px"}),
            html.Div(c["sub"], style={"fontSize": "11px", "color": COLORS["text_secondary"],
                                       "marginTop": "4px"}),
        ], style={
            "backgroundColor": COLORS["card_bg"], "borderRadius": "12px",
            "padding": "20px 16px", "textAlign": "center",
            "border": f"1px solid {COLORS['grid']}", "flex": "1", "minWidth": "150px",
        }))
    return cards


# ============================================================================
# LAYOUT
# ============================================================================

app.layout = html.Div([
    # Header
    html.Div([
        html.Div([
            html.Span("📊", style={"fontSize": "32px", "marginRight": "12px"}),
            html.Span(PROJECT_NAME, style={"fontSize": "24px", "fontWeight": "700",
                                            "color": COLORS["text"]}),
            html.Span(" — Non-Financial KPI Dashboard",
                       style={"fontSize": "16px", "color": COLORS["text_secondary"],
                              "marginLeft": "8px"}),
        ], style={"display": "flex", "alignItems": "center"}),
        html.Div([
            html.Span(f"Updated: {PROJECT_DATE}",
                       style={"fontSize": "12px", "color": COLORS["text_secondary"]}),
            html.Span(" · ", style={"color": COLORS["grid"], "margin": "0 8px"}),
            html.Span(PROJECT_AUTHOR,
                       style={"fontSize": "12px", "color": COLORS["blue"]}),
        ]),
    ], style={
        "display": "flex", "justifyContent": "space-between", "alignItems": "center",
        "padding": "16px 32px", "backgroundColor": COLORS["card_bg"],
        "borderBottom": f"1px solid {COLORS['grid']}",
    }),

    # Body
    html.Div([
        # KPI Cards
        html.Div(create_kpi_cards(), style={"display": "flex", "gap": "12px",
                                             "marginBottom": "20px", "flexWrap": "wrap"}),
        # Row 1: Radar + Load vs Quality
        html.Div([
            html.Div(dcc.Graph(figure=create_radar_chart(), config={"displayModeBar": False}),
                     style={"flex": "1", "minWidth": "450px", "backgroundColor": COLORS["card_bg"],
                            "borderRadius": "12px", "border": f"1px solid {COLORS['grid']}"}),
            html.Div(dcc.Graph(figure=create_load_vs_quality_chart(), config={"displayModeBar": False}),
                     style={"flex": "1", "minWidth": "450px", "backgroundColor": COLORS["card_bg"],
                            "borderRadius": "12px", "border": f"1px solid {COLORS['grid']}"}),
        ], style={"display": "flex", "gap": "16px", "marginBottom": "16px", "flexWrap": "wrap"}),

        # Row 2: Debt Gauge
        html.Div(dcc.Graph(figure=create_debt_gauge(), config={"displayModeBar": False}),
                 style={"backgroundColor": COLORS["card_bg"], "borderRadius": "12px",
                        "border": f"1px solid {COLORS['grid']}", "marginBottom": "16px"}),

        # Row 3: Risk + Team Diversity
        html.Div([
            html.Div(dcc.Graph(figure=create_risk_chart(), config={"displayModeBar": False}),
                     style={"flex": "1", "minWidth": "450px", "backgroundColor": COLORS["card_bg"],
                            "borderRadius": "12px", "border": f"1px solid {COLORS['grid']}"}),
            html.Div(dcc.Graph(figure=create_team_diversity_chart(), config={"displayModeBar": False}),
                     style={"flex": "1", "minWidth": "450px", "backgroundColor": COLORS["card_bg"],
                            "borderRadius": "12px", "border": f"1px solid {COLORS['grid']}"}),
        ], style={"display": "flex", "gap": "16px", "marginBottom": "16px", "flexWrap": "wrap"}),

        # Row 4: CI/CD Heatmap
        html.Div(dcc.Graph(figure=create_cicd_heatmap(), config={"displayModeBar": False}),
                 style={"backgroundColor": COLORS["card_bg"], "borderRadius": "12px",
                        "border": f"1px solid {COLORS['grid']}", "marginBottom": "16px"}),

        # Footer
        html.Div([
            html.Span("Open Source Template — MIT License · ", style={"color": COLORS["text_secondary"]}),
            html.Span("Adapt the DATA section to your project",
                       style={"color": COLORS["blue"]}),
        ], style={"textAlign": "center", "padding": "16px", "fontSize": "12px",
                  "borderTop": f"1px solid {COLORS['grid']}"}),
    ], style={"padding": "20px 32px"}),
], style={
    "backgroundColor": COLORS["bg"], "minHeight": "100vh",
    "fontFamily": "'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif",
})


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    print(f"\n📊 {PROJECT_NAME} — Non-Financial KPI Dashboard")
    print("=" * 50)
    print("🚀 Running at http://127.0.0.1:8050")
    print("   Press Ctrl+C to stop.\n")
    app.run(debug=True, host="127.0.0.1", port=8050)
