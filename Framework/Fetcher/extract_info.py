import re
import os
import fitz
import json
import logging
from tqdm import tqdm
from urllib.parse import urlparse
from dataclasses import dataclass
from collections import Counter
from Framework.Fetcher.utils import GithubUrlParser, GithubUrl


# Define regex constants
ONCHAIN_ADDRESS = r"\b0x[a-fA-F0-9]{40}\b"
SHA1_LONG = r"\b[A-Fa-f0-9]{40}\b"
SHA1_SHORT = r"\b[A-Fa-f0-9]{10}\b"
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
]
# https://github.com/traderjoe-xyz/joe-core/tree/27c7c77c392e4c644d3c7d23f700e088e9a2903e

# blob->file, tree->dir, commit->branch


def match_regex(text, regex):
    res = re.search(regex, text)
    if res:
        return res.group(0)
    return None


def verify_url(url: str):

    parser = GithubUrlParser(url)
    return bool(
        parser.info.owner
        and parser.info.repo
        and parser.info.proj
        and parser.info.owner not in WRONG_LIST
        and parser.info.repo not in WRONG_LIST
    )


def verify_address(address: str):
    return bool(re.match(ONCHAIN_ADDRESS, address))


def extract_address(content: str):
    res = re.findall(ONCHAIN_ADDRESS, content)
    if res:
        counter = Counter(res)
        return counter.most_common(1)[0][0]
    return None


def extract_url_from_pdf(json_file):
    # DONE: check if .md file

    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)
        if data["path"].split(".")[-1] != "pdf":
            logging.debug("Not a pdf file: %s", data["path"])
            logging.debug("url: %s", data["project_info"]["url"])
            return
        pdf_path = "D:/Projects/202311_Reporsis" + data["path"][1:]
        logging.debug("Processing: \n%s", pdf_path)
        doc = fitz.open(pdf_path)
        urls = {}

        project_info = data["project_info"]

        finished = verify_url(str(project_info["url"]))
        finished_addr = verify_address(str(project_info["address"]))
        if finished_addr:
            logging.debug("Address already mined: %s", project_info["address"])
        if not finished_addr:
            page_content = ""
            for page_num in range(len(doc)):

                page = doc[page_num]
                page_content += page.get_text()
                links = page.links()
                for link in links:
                    page_content += "\n"
                    page_content += link.get("uri", "")
            addr = extract_address(page_content)
            if addr:
                project_info["address"] = addr
                finished_addr = True
                logging.debug("Address: %s", addr)
        if finished:
            logging.debug("URL already mined: %s", project_info["url"])
            return
        else:
            project_info["url"] = "N/A"
        for page_num in range(len(doc)):
            if finished:
                break
            page = doc[page_num]
            links = page.links()
            for link in links:
                linkText = link.get("uri")
                url_res = GithubUrlParser(linkText).info
                if (
                    url_res.owner
                    and url_res.repo
                    and url_res.branch
                    and url_res.owner not in WRONG_LIST
                    and url_res.repo not in WRONG_LIST
                ):
                    project_info["url"] = url_res.proj
                    project_info["commit_hash"] = url_res.branch
                    logging.debug(
                        "URL with commit id: %s, %s",
                        project_info["url"],
                        project_info["commit_hash"],
                    )
                    finished = True
                    break
                if (
                    url_res.owner
                    and url_res.repo
                    and url_res.owner not in WRONG_LIST
                    and url_res.repo not in WRONG_LIST
                ):
                    urls[url_res.proj] = urls.get(url_res.proj, 0) + 1

        if not finished and urls:
            project_info["url"] = sorted(
                urls.items(), key=lambda item: item[1], reverse=True
            )[0][0]
        # print(sorted(urls.items(), key=lambda item: item[1], reverse=True))
        logging.debug("URL: %s", project_info["url"])

        data["project_info"] = project_info
        with open(json_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)


def process(dir: str):
    for root, dirs, files in os.walk(dir):
        for file in tqdm(files):
            if file.endswith(".json"):
                try:
                    extract_url_from_pdf(os.path.join(root, file))
                except Exception as e:
                    logging.error("Error: %s", e)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    # test_url = "https://github.com/traderjoe-xyz/joe-core/blob/27c7c77c392e4c644d3c7d23f700e088e9a2903e/contracts/BoostedMasterChefJoe.sol#L32-L540"
    # parser = GithubUrlParser(test_url)
    # print(parser.info)
    # extract_url_from_pdf(
    #     r"Experiments\original\Ackee_Blockchain\Ackee_Blockchain-Ackee_Blockchain_audited_Trader_Joe_files2.json"
    # )
    process(r"Experiments\original")
