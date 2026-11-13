"""End-to-end pipeline: load UCI Online Retail -> SQLite -> run SQL -> export results + charts.

Usage:  python src/run_pipeline.py
"""
import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw" / "Online Retail.xlsx"
DB = ROOT / "data" / "retail.db"
SQL = ROOT / "sql"
OUT = ROOT / "outputs"
OUT.mkdir(exist_ok=True)


def run_script(con, name):
    con.executescript((SQL / name).read_text(encoding="utf-8"))


def run_queries(con, name):
    """Run each ';'-terminated statement of a SQL file that is a SELECT; return list of DataFrames."""
    text = "\n".join(l for l in (SQL / name).read_text(encoding="utf-8").splitlines()
                     if not l.strip().startswith("--"))
    stmts = [s.strip() for s in text.split(";") if s.strip()]
    return [pd.read_sql_query(s, con) for s in stmts]


def load_raw(con):
    print("Reading Excel (takes ~1 min)...")
    df = pd.read_excel(RAW, dtype={"InvoiceNo": str, "StockCode": str})
    df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"]).dt.strftime("%Y-%m-%d %H:%M:%S")
    df.to_sql("online_retail_raw", con, if_exists="replace", index=False)
    print(f"Loaded {len(df):,} rows")


def charts(seg, monthly):
    order = seg.sort_values("customers", ascending=True)
    fig, ax = plt.subplots(1, 2, figsize=(13, 5))
    ax[0].barh(order["segment"], order["customers"], color="#4C78A8")
    ax[0].set_title("Customers per segment")
    rev = seg.sort_values("pct_revenue", ascending=True)
    ax[1].barh(rev["segment"], rev["pct_revenue"], color="#F58518")
    ax[1].set_title("% of revenue per segment")
    for a in ax:
        a.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT / "segments.png", dpi=130)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(monthly["month"], monthly["revenue"], marker="o", color="#4C78A8")
    ax.set_title("Monthly revenue (cleaned data)")
    ax.tick_params(axis="x", rotation=45)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT / "monthly_revenue.png", dpi=130)
    plt.close(fig)


def main():
    first = not DB.exists()
    con = sqlite3.connect(DB)
    if first:
        load_raw(con)
    for name in ("02_clean_view.sql", "03_rfm_segmentation.sql"):
        run_script(con, name)

    for i, df in enumerate(run_queries(con, "01_data_quality.sql"), 1):
        print(f"\n[data quality {i}]\n{df.to_string(index=False)}")
        df.to_csv(OUT / f"data_quality_{i}.csv", index=False)

    q1, q2, q3, q4 = run_queries(con, "04_segment_analysis.sql")
    for n, df in zip(("segment_summary", "top_countries", "repeat_vs_onetime", "monthly_trend"), (q1, q2, q3, q4)):
        df.to_csv(OUT / f"{n}.csv", index=False)
        print(f"\n[{n}]\n{df.to_string(index=False)}")

    pd.read_sql_query("SELECT * FROM rfm_segments ORDER BY monetary DESC", con).to_csv(
        OUT / "rfm_segments.csv", index=False)
    charts(q1, q4)
    con.close()
    print("\nDone. See outputs/")


if __name__ == "__main__":
    main()
