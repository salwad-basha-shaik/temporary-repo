import requests
import json
import os
import re

API1 = "https://app.opsera.io/api/v2/insights/tool-mappings?limit=100"
API2_BASE = "https://app.opsera.io/api/v2/insights/tool-mappings"
BEARER_TOKEN = "YOUR_BEARER_TOKEN_HERE"

HEADERS = {
    "Authorization": f"Bearer {BEARER_TOKEN}",
    "Content-Type": "application/json"
}

def sanitize_filename(name: str) -> str:
    # Replace any characters not safe for filenames
    safe_name = re.sub(r'[\\/*?:"<>|]', "_", name)
    return safe_name.replace(" ", "_").replace("-", "_")

def main():
    try:
        response = requests.get(API1, headers=HEADERS)
        response.raise_for_status()
        api1_data = response.json()
    except Exception as e:
        print(f"Error fetching API1: {e}")
        return

    data_list = api1_data.get("data", [])
    if not data_list:
        print("No data found in API1 response.")
        return

    output_dir = os.getcwd()

    for index, item in enumerate(data_list, start=1):
        record_id = item.get("id")
        if not record_id:
            continue

        api2_url = f"{API2_BASE}/{record_id}"
        try:
            api2_response = requests.get(api2_url, headers=HEADERS)
            api2_response.raise_for_status()
            api2_data = api2_response.json()
        except Exception as e:
            print(f"Error fetching API2 for ID {record_id}: {e}")
            continue

        project_value = api2_data.get("Project", "UnknownProject")
        safe_project = sanitize_filename(project_value)

        filename = f"{index}_{safe_project}.md"
        filepath = os.path.join(output_dir, filename)

        try:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(f"- URL:\n    - {api2_url}\n\n")
                f.write("```json\n")
                json.dump(api2_data, f, indent=4)
                f.write("\n```")
            print(f"✅ Saved: {filename}")
        except Exception as e:
            print(f"⚠️ Error saving file {filename}: {e}")

if __name__ == "__main__":
    main()
