from dataclasses import dataclass
from urllib.parse import urlparse
from typing import Literal
import json
import os


@dataclass
class Address:
    address: str
    network: str = ""
    account_type: str = ""


@dataclass
class GithubUrl:
    href: str
    git_url: str = ""
    proj: str = ""
    owner: str = ""
    repo: str = ""
    branch: str = ""
    dir_name: str = ""
    file_name: str = ""
    fragment: str = ""


class StopIteration(Exception):
    # exit
    pass


# GithubUrl(
#     href="https://github.com/traderjoe-xyz/joe-core/tree/27c7c77c392e4c644d3c7d23f700e088e9a2903e",
#     owner="traderjoe-xyz",
#     repo="joe-core",
#     branch="27c7c77c392e4c644d3c7d23f700e088e9a2903e",
#     dir="",
#     file="",
# )
BASE_URL = ["github.com", "gitlab.com"]


class AddressParser:
    def __init__(self, addr: str):
        pass


class GitlabUrlParser:
    def __init__(self, url: str):
        self.info = GithubUrl(href=url)
        self.parsed_url = urlparse(url)
        self._parse()

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
        self.info.git_url = (
            f"https://{self.parsed_url.netloc}/{self.info.owner}/{self.info.repo}"
        )


def write_json(data, path):
    with open(path, "w", encoding="utf-8") as fj:
        json.dump(data, fj, indent=4)


def read_json(path):
    with open(path, "r", encoding="utf-8") as fj:
        return json.load(fj)


def path_handle(input_path: str, dataset_path: str):
    common_path = os.path.commonpath([input_path, dataset_path])
    display_path = os.path.relpath(dataset_path, common_path)
    display_path = os.path.join(os.path.basename(common_path), display_path)
    return display_path


def get_log_status(log_path: str):
    if not os.path.exists(log_path):
        return {"info": [], "error": [], "warning": []}
    else:
        log_info = read_json(log_path)
        return log_info


def log_to_file(
    log_path: str, log_type: Literal["info", "error", "warning"], message: str
):

    if not os.path.exists(log_path):
        write_json({"info": [], "error": [], "warning": []}, log_path)
    log_info = read_json(log_path)
    log_info[log_type] = log_info.get(log_type, [])
    log_info[log_type].append(message)
    write_json(log_info, log_path)
