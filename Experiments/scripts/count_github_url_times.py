import os
import json
import argparse

# import matplotlib.pyplot as plt
from dataclasses import dataclass
from urllib.parse import urlparse


@dataclass
class GithubUrl:
    href: str
    repo_url: str = ""
    proj: str = ""
    owner: str = ""
    repo: str = ""
    branch: str = ""
    dir_name: str = ""
    file_name: str = ""
    fragment: str = ""


BASE_URL = ["github.com", "gitlab.com"]


class GithubUrlParser:
    def __init__(self, url: str):
        self.info = GithubUrl(href=url)
        self.parsed_url = urlparse(url)
        self._parse()

    def add_branch(self, commit_id: str):
        self.info.branch = commit_id
        self.info.proj = f"https://{self.parsed_url.netloc}/{self.info.owner}/{self.info.repo}/tree/{commit_id}"

    def _parse(self):
        if self.parsed_url.netloc not in BASE_URL:
            return
        path = self.parsed_url.path
        fragment = self.parsed_url.fragment
        if path:
            path_parts = path.strip("/").split("/")
            if len(path_parts) >= 2:
                self.info.owner = path_parts[0]
                self.info.repo = path_parts[1]
                self.info.repo_url = f"https://{self.parsed_url.netloc}/{self.info.owner}/{self.info.repo}"
                self.info.proj = f"https://{self.parsed_url.netloc}/{self.info.owner}/{self.info.repo}"
            if len(path_parts) >= 4:
                if path_parts[2] == "tree":
                    self.info.branch = path_parts[3]
                    self.info.dir_name = "/".join(path_parts[4:])
                elif path_parts[2] == "blob":
                    self.info.branch = path_parts[3]
                    self.info.file_name = "/".join(path_parts[4:])
                elif path_parts[2] == "commit":
                    self.info.branch = path_parts[3]
            if self.info.branch:
                self.info.proj = f"{self.info.proj}/tree/{self.info.branch}"

        if fragment:
            self.info.fragment = fragment


def count_github_url(source_dir):
    all_json_files = []

    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))
    print(f"Total number of JSON files: {len(all_json_files)}")

    github_url = {}
    for file_path in all_json_files:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            if data["project_info"].get("is_exists", False):
                url = data["project_info"]["url"]
                parser = GithubUrlParser(url)
                # if parser.info.repo_url == "":
                #     print(data["path"])
                #     print(file_path)
                github_url[parser.info.repo_url] = (
                    github_url.get(parser.info.repo_url, 0) + 1
                )

            # json.dump(data, f, indent=4)

    github_url = dict(sorted(github_url.items(), key=lambda x: x[1], reverse=True))
    # 打印github_url 排名前十的field
    for key in list(github_url.keys())[:20]:
        print(key, github_url[key])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Count the total number of defects in all JSON files in a directory and its subdirectories."
    )

    parser.add_argument(
        "--source_dir",
        default="Experiments/original",
        help="Source directory containing JSON files",
        required=False,
    )

    args = parser.parse_args()

    count_github_url(args.source_dir)
