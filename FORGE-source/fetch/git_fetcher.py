import os
import re
import csv
import json
import requests
import logging
from typing import Literal
from utils import GithubUrl, GithubUrlParser


class Git_Fetcher:
    """
    fetch the source code from github
    """

    def __init__(self):
        self.github_token = os.getenv("GITHUB_TOKEN")

    def parse_address(self, original_addr: str) -> list:
        """
        extract addresses from unstructured text
        """
        address = []
        addr_list: list = original_addr.split(",")
        for addr in addr_list:
            match_str = re.search(self.addr_parser, addr)
            if match_str:
                address.append(match_str.group())
        return address

    def parse_code(self, contract_name: str, source_code: str) -> dict:
        """
        parse source code strings that may contain multiple sol files
        """
        pass

    def fetch_code(self, url: str, branch: str) -> dict:
        """
        fetch the source code from github
        """
        url_res = GithubUrlParser(url)
        if not url_res.info.owner:
            return {}
        if not url_res.info.branch and branch:
            url_res.add_branch(branch)
        pass
