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
        url = GithubUrlParser(original_url).info

        if url.branch is None and branch_id is not "":
            GithubUrlParser.add_branch(branch_id)
        if url is None:
            logging.error("Invalid URL")
            return None
        if url.repo in WRONG_LIST:
            logging.error("Abandoned Github Repo (Wrong List)")
            return None
        return url

    def clone_repo(self, url: GithubUrl, output_path: str) -> Literal[0, 1]:
        if url is None:
            return 0
        if not os.path.exists(output_path):
            os.makedirs(output_path)
        try:
            git.Repo.clone_from(url.git_url, output_path)
        except Exception as e:
            logging.error(f"Failed to clone the repo: {e}")
            return 0

        return 1
