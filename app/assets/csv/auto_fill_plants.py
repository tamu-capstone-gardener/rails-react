import os
import pandas as pd
import time
from openai import OpenAI
from tqdm import tqdm

# Set up the OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Load your CSV
df = pd.read_csv("./sven_plants.csv", dtype=str)

def is_empty(val):
    return pd.isna(val) or str(val).strip() in ("", "[]")

target_columns = [
    "GrowthRate", "HardinessZones", "Width", "Leaf", "Flower", "Ripen", "Tolerances"
]

def build_prompt(row, incomplete_cols):
    info = f"""The following plant has missing attributes. Fill in each field with a realistic, concise value:

- Family: {row.get('Family', '')}
- Genus: {row.get('Genus', '')}
- Species: {row.get('Species', '')}
- Common Name: {row.get('CommonName', '')}

Provide values for the following:
"""
    for col in incomplete_cols:
        info += f"- {col}:\n"
    return info.strip()

def parse_gpt_output(output, incomplete_cols):
    lines = output.strip().splitlines()
    result = {}
    for col in incomplete_cols:
        for line in lines:
            if line.lower().startswith(f"- {col.lower()}"):
                val = line.split(":", 1)[-1].strip()
                result[col] = val
                break
    return result

# Process each row with missing data
for idx, row in tqdm(df.iterrows(), total=len(df)):
    incomplete_cols = [col for col in target_columns if is_empty(row[col])]
    if not incomplete_cols:
        continue

    prompt = build_prompt(row, incomplete_cols)

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a botanical database assistant that helps complete missing plant info."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
        )

        reply = response.choices[0].message.content
        updates = parse_gpt_output(reply, incomplete_cols)

        for col, val in updates.items():
            if val:
                df.at[idx, col] = val

        time.sleep(1.5)  # rate limit buffer
    except Exception as e:
        print(f"Error at row {idx}: {e}")

# Save the result
output_file = "./sven_plants_filled.csv"
df.to_csv(output_file, index=False)
print(f"✅ Done! Output saved to '{output_file}'")
