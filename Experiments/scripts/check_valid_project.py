import os
import json
import argparse


def check_github_url(url):
    # check if the url can be accessed
    pass


def count_valid_project(source_dir):
    all_json_files = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))

    print(f"Total projects: ", len(all_json_files))
    all_valid_project = 0
    valid_github_proj = 0
    all_defects = 0
    for file_path in all_json_files:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            url = data["project_info"]["url"]
            address = data["project_info"]["address"]
            is_exists = data["project_info"].get("is_exists", False)
            if not url and not address:
                continue
            if url == "N/A" and address == "N/A":
                continue
            if url != "N/A" and not is_exists:
                # all_valid_project += 1
                continue
            else:
                all_defects += len(data["findings"])
                all_valid_project += 1
                # continue
            if url != "N/A" and is_exists:
                valid_github_proj += 1
    print(f"Total number of valid projects in all JSON files: {all_valid_project}")
    print(
        f"Total number of valid GitHub projects in all JSON files: {valid_github_proj}"
    )
    print(f"Total number of defects in all JSON files: {all_defects}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Count the total number of defects in all JSON files in a directory and its subdirectories."
    )

    parser.add_argument(
        "--source_dir",
        default="Experiments\original",
        help="Source directory containing JSON files",
        required=False,
    )

    args = parser.parse_args()

    count_valid_project(args.source_dir)
