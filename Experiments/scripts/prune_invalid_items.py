import os
import json
import argparse


def prune_na(source_dir):
    all_json_files = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))

    all_na_defects = 0
    for file_path in all_json_files:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            finding2 = []
            for finding in data["findings"]:
                if finding["description"] == "N/A":
                    all_na_defects += 1
                    continue

                finding2.append(finding)
            data["findings"] = finding2
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)

    print(f"Total number of N/A defects in all JSON files: {all_na_defects}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Count the total number of defects in all JSON files in a directory and its subdirectories."
    )

    parser.add_argument(
        "--source_dir",
        default="Experiments\sample",
        help="Source directory containing JSON files",
        required=False,
    )

    args = parser.parse_args()

    prune_na(args.source_dir)
