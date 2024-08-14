import os
import json
import argparse
import matplotlib.pyplot as plt


def count_cwe_num(source_dir):
    all_json_files = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))
    print(f"Total number of JSON files: {len(all_json_files)}")

    cwe_distribution = {}
    for file_path in all_json_files:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            for finding in data["findings"]:
                if finding["category"] == []:
                    continue
                cwe = finding.get("category", {}).get("1", "")[0]
                if not cwe:
                    continue
                if cwe in cwe_distribution:
                    cwe_distribution[cwe] += 1
                else:
                    cwe_distribution[cwe] = 1
            # json.dump(data, f, indent=4)

    cwe_distribution = dict(
        sorted(cwe_distribution.items(), key=lambda x: x[1], reverse=True)
    )
    print(f"CWE distribution: {cwe_distribution}")
    # draw a bar graph use the cwe_distribution dictionary
    # 小于10个CWE类别的不画图
    for key in list(cwe_distribution.keys()):
        if cwe_distribution[key] < 10:
            cwe_distribution.pop(key)  # 条形图上标上数字

    plt.bar(
        cwe_distribution.keys(), cwe_distribution.values(), width=0.5, color="skyblue"
    )
    for a, b in zip(cwe_distribution.keys(), cwe_distribution.values()):
        plt.text(a, b + 0.05, "%.0f" % b, ha="center", va="bottom", fontsize=7)
    plt.xticks(rotation=30)
    plt.xlabel("CWE")
    plt.ylabel("Number of defects")
    plt.title("CWE distribution")
    plt.show()


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

    count_cwe_num(args.source_dir)
