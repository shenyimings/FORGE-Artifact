import os
import re
import csv
import git
import json
import requests
import logging
from github import Github, Auth
from typing import Literal
from builder.utils import GithubUrl, GithubUrlParser

BASE_URL = ["github.com", "gitlab.com"]
WRONG_LIST = [
    "OpenZeppelin",
    "Ackee-Blockchain",
    "wake",
    "woke",
    "ethereum",
    "eips",
    "crytic",
    "slither",
    "GNSPS",
    "OpenVPN",
    "Save-app-android",
    "curl",
    "trailofbits",
    "OpenArchive",
    "bitcoin",
    "eclipse",
    "keda",
    "paulmillr",
    "runtimeverification",
    "cyberscope-io",
    "ConsenSys",
    "go-fuzz",
    "oyente",
    "MAIAN",
    "mythril",
    "solhint",
    "BEPs",
    "OWASP",
    "hardhat",
    "rustsec",
    "vyper",
    "SkeletonEcosystem",
    "Synthetixio",
    "Smart-Contract-Audit-Reports",
    "SCSTG",
    "ic",
    "Audits",
    "audits",
    "Audit-Reports",
    "Audit_Reports",
    "Smart_Contract_Audit_Reports"
]


class GitFetcher:
    """
    fetch the source code from github
    """

    def __init__(self):
        self.github_token = os.getenv("GITHUB_TOKEN")

    def auth(self):
        if self.github_token is None:
            logging.error("Github token is not found")
            return None
        auth = Auth.Token(self.github_token)
        self.g = Github(auth=auth)
        return self.g

    def parse_url(self, original_url: str, branch_id: str = "") -> GithubUrl:
        url = GithubUrlParser(original_url)

        if url.info.branch is "" and branch_id is not "":
            url.add_branch(branch_id)
        if url.info is None:
            logging.error("Invalid URL")
            return None
        if url.info.repo in WRONG_LIST:
            logging.warning("Abandoned Github Repo (Wrong List)")
            return None
        return url.info

    def clone_repo(self, url: GithubUrl, output_path: str) -> Literal[0, 1]:
        if url is None:
            return 0
        if not os.path.exists(output_path):
            os.makedirs(output_path, exist_ok=True)
        try:
            git.Repo.clone_from(url.git_url, output_path)
        except Exception as e:
            logging.warning(f"Failed to clone the repo: {e}")
            # check if the output_path is empty
            if not os.listdir(output_path):
                os.rmdir(output_path)
                return 0
            return 1

        return 1

    # checkout to specify commit_id
    def check_out(self, repo_path: str, commit_id: str) -> Literal[0, 1]:
        if commit_id == "N/A" or commit_id is None or commit_id == "":
            return 0
        try:
            repo = git.Repo(repo_path)
            repo.git.checkout(commit_id)
        except Exception as e:
            logging.error(f"Failed to checkout: {e}")
            return 0
        return 1
