"""
python3 random_sampling.py sample_size source_directory sample_directory  output.csv
"""

import os
import random
import shutil
import csv
import argparse


def sample_json_files(source_dir, sample_dir, sample_size, output_csv):
    all_json_files = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))

    sample_size = min(sample_size, len(all_json_files))

    sampled_files = random.sample(all_json_files, sample_size)

    os.makedirs(sample_dir, exist_ok=True)

    sampled_list = []
    for file in sampled_files:
        dest = os.path.join(sample_dir, os.path.basename(file))
        shutil.copy2(file, dest)
        sampled_list.append([file, dest])

    with open(output_csv, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["Source Path", "Destination Path"])
        writer.writerows(sampled_list)

    print(f"Sampled {sample_size} JSON files and copied to {sample_dir}")
    print(f"List of sampled files saved to {output_csv}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Randomly sample JSON files from a directory and its subdirectories."
    )
    parser.add_argument(
        "--sample_size",
        type=int,
        default=96,
        help="Number of JSON files to sample",
        required=False,
    )
    parser.add_argument(
        "--source_dir",
        default="../original",
        help="Source directory containing JSON files",
        required=False,
    )
    parser.add_argument(
        "--sample_dir",
        default="../sample",
        help="Directory to store sampled JSON files",
        required=False,
    )
    parser.add_argument(
        "--output_csv",
        default="../sample_list.csv",
        help="Path to the output CSV file",
        required=False,
    )

    args = parser.parse_args()

    sample_json_files(
        args.source_dir, args.sample_dir, args.sample_size, args.output_csv
    )
