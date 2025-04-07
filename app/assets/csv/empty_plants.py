import pandas as pd

# Load your CSV
df = pd.read_csv("./sven_plants.csv", dtype=str)

def is_empty(val):
    return pd.isna(val) or str(val).strip() in ("", "[]")

target_columns = [
    "GrowthRate", "HardinessZones", "Width", "Leaf", "Flower", "Ripen", "Tolerances"
]

# Print out the incomplete rows
for idx, row in df.iterrows():
    incomplete_cols = [col for col in target_columns if is_empty(row[col])]
    if incomplete_cols:
        print(f"Row {idx}: missing {', '.join(incomplete_cols)}")
