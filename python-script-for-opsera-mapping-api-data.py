import requests
import json
import os

# Base API endpoints
API1 = "https://app.opsera.io/api/v2/insights/tool-mappings?limit=100"
API2_BASE = "https://app.opsera.io/api/v2/insights/tool-mappings"

# Enter your Bearer Token here (keep it safe!)
BEARER_TOKEN = "YOUR_BEARER_TOKEN_HERE"

# Common headers for both APIs
HEADERS = {
    "Authorization": f"Bearer {BEARER_TOKEN}",
    "Content-Type": "application/json"
}

def main():
    try:
        # Step 1: Call API1 with Bearer token
        response = requests.get(API1, headers=HEADERS)
        response.raise_for_status()
        api1_data = response.json()
    except Exception as e:
        print(f"Error fetching API1: {e}")
        return

    # Step 2: Extract IDs
    data_list = api1_data.get("data", [])
    if not data_list:
        print("No data found in API1 response.")
        return

    output_dir = os.getcwd()

    for index, item in enumerate(data_list, start=1):
        record_id = item.get("id")
        if not record_id:
            continue

        # Step 3: Call API2 for each ID with Bearer token
        api2_url = f"{API2_BASE}/{record_id}"
        try:
            api2_response = requests.get(api2_url, headers=HEADERS)
            api2_response.raise_for_status()
            api2_data = api2_response.json()
        except Exception as e:
            print(f"Error fetching API2 for ID {record_id}: {e}")
            continue

        # Step 4: Extract project name for filename
        project_value = api2_data.get("Project", "UnknownProject").replace(" ", "_").replace("-", "_")

        # Step 5: Create markdown file
        filename = f"{index}_{project_value}.md"
        filepath = os.path.join(output_dir, filename)

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(f"- URL:\n    - {api2_url}\n\n")
            f.write("```json\n")
            json.dump(api2_data, f, indent=4)
            f.write("\n```")

        print(f"✅ Saved: {filename}")

if __name__ == "__main__":
    main()
