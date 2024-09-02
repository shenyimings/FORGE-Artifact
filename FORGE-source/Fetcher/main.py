# Check EOA or Contract Address
# Try both Etherscan & Bscscan
# Check Github stars, exceeds 500 stars should be careful
import os
import json
import dotenv
import logging
import requests
from tqdm import tqdm
from time import sleep

from chain_fetcher import Addr_Fetcher

# from Framework.Fetcher.git_fetcher import fetch_git
from utils import GithubUrl, GithubUrlParser

API_BASE = "https://api.github.com/repos"
MAX_RETRY = 3


def get_star_count(url: GithubUrl):
    api_url = f"{API_BASE}/{url.owner}/{url.repo}"
    api_token = os.getenv("GITHUB_TOKEN")
    headers = {"Accept": "application/vnd.github+json"}
    headers["Authorization"] = f"Bearer {api_token}"
    retry_times = 0

    while retry_times < MAX_RETRY:
        response = requests.get(api_url, headers=headers)
        repo_info = response.json()
        if response.status_code == 200:
            star_count = repo_info.get("stargazers_count", 0)
            return star_count
        if response.status_code == 403:
            logging.error("API rate limit exceeded")
            retry_times += 1
            sleep(1)
            continue
        if response.status_code == 404:
            logging.error("Repo not found or private")
            return -1
        else:
            logging.error(str(response.json()))
            logging.error(f"Failed to fetch {url.href}")
            return -2


def write_json(data, path):
    with open(path, "w", encoding="utf-8") as fj:
        json.dump(data, fj, indent=4)


def fetch_stars(path: str):
    # result = {"Finished":[path,...],"Warning":[{path:reason},...], "Failed":[{path:reason},...]}
    private_count = 0
    with open("Framework/Fetcher/result.json", "r", encoding="utf8") as f:
        result = json.load(f)
    for root, dirs, files in os.walk(path):
        for f in tqdm(files):
            if f in result["Finished"]:
                continue
            if f.endswith(".json"):
                try:
                    with open(os.path.join(root, f), "r", encoding="utf-8") as fj:
                        data = json.load(fj)
                        url = data["project_info"]["url"]
                        if not url or url == "N/A":
                            continue
                        url_res = GithubUrlParser(url)
                        if not url_res.info.owner:
                            continue
                        if (
                            not url_res.info.branch
                            and data["project_info"]["commit_hash"]
                            and data["project_info"]["commit_hash"] != "N/A"
                        ):
                            url_res.add_branch(data["project_info"]["commit_hash"])
                        star_count = get_star_count(url_res.info)
                        sleep(0.2)
                        if star_count > 500:
                            result["Warning"].append(
                                {
                                    str(
                                        os.path.join(
                                            root,
                                            f,
                                        )
                                    ): "Stars exceed 500"
                                }
                            )
                            result["Finished"].append(f)
                            write_json(result, "Framework/Fetcher/result.json")
                            continue
                        if star_count == -1:
                            # data["project_info"]["url"] = "N/A"
                            # data["project_info"]["commit_hash"] = "N/A"
                            data["project_info"]["is_exists"] = False
                            # logging.debug(f"{f}\nRepo not found or private: {url}")
                            private_count += 1
                            print(f"{f}\nRepo not found or private: {url}")
                            print(f"Invalid count: {private_count}")
                            result["Finished"].append(f)
                            write_json(result, "Framework/Fetcher/result.json")
                            write_json(data, os.path.join(root, f))
                            continue
                        if star_count == -2:
                            result["Failed"].append(
                                {str(os.path.join(root, f)): "Failed to fetch"}
                            )
                            write_json(result, "Framework/Fetcher/result.json")
                            continue

                        data["project_info"]["is_exists"] = True
                        write_json(data, os.path.join(root, f))
                        result["Finished"].append(f)
                        write_json(result, "Framework/Fetcher/result.json")

                except Exception as e:
                    result["Failed"].append({f: str(e)})
                    continue


def edit_json():
    for root, dirs, files in os.walk("Experiments/original"):
        for dirfile in files:

            with open(os.path.join(root, dirfile), "r", encoding="utf-8") as f:
                data = json.load(f)
                if (
                    data["project_info"]["url"] != "N/A"
                    and data["project_info"].get("is_exists", 6) == 6
                ):
                    if GithubUrlParser(data["project_info"]["url"]).info.owner:
                        data["project_info"]["is_exists"] = True
                        print(os.path.join(root, dirfile))
                        # print(data["project_info"]["url"])
                        # print()
                        with open(
                            os.path.join(root, dirfile), "w", encoding="utf-8"
                        ) as f:
                            json.dump(data, f, indent=4)


def walk_datasets(name: str, path: str, output_dir: str = "Experiments/contracts"):
    # result = {"Finished":[path,...],"Warning":[{path:reason},...], "Failed":[{path:reason},...]}
    if not os.path.exists(f"Framework/Fetcher/{name}_result.json"):
        with open(f"Framework/Fetcher/{name}_result.json", "w", encoding="utf8") as f:
            json.dump({"Finished": [], "Warning": [], "Failed": []}, f)
    with open(f"Framework/Fetcher/{name}_result.json", "r", encoding="utf8") as f:
        result = json.load(f)

    fetcher = Addr_Fetcher()

    for root, dirs, files in os.walk(path):
        for f in tqdm(files):
            # if f != "1-bcp.json":
            #     continue
            if f in result["Finished"]:
                continue
            if f in result["Failed"]:
                continue
            if f.endswith(".json"):
                try:
                    with open(os.path.join(root, f), "r", encoding="utf-8") as fj:
                        data = json.load(fj)
                        if (
                            not data["project_info"]["address"]
                            or data["project_info"]["address"] == "N/A"
                            or data["project_info"].get("is_exists", False)
                        ):
                            continue
                        addrs = fetcher.parse_address(data["project_info"]["address"])
                        print("\n", os.path.join(root, f))
                        print("\n", addrs)
                        isSuccessful = False
                        infoToAdd = {}
                        chain = ""
                        compilerVersion = set()
                        for addr in addrs:
                            res = fetcher.fetch_code(
                                addr, os.path.join(output_dir, f.split(".")[0])
                            )
                            sleep(0.6)
                            if not res:
                                continue
                            isSuccessful = True
                            # print(res["contractName"])
                            chain = res["chain"]
                            compilerVersion.add(res["compilerVersion"])
                            infoToAdd[res["contractName"]] = res["contractPath"]
                        if isSuccessful:
                            data["project_info"]["chain"] = chain
                            data["project_info"]["compilerVersion"] = list(
                                compilerVersion
                            )
                            data["project_info"]["project_path"] = infoToAdd
                            # print(data)
                            write_json(data, os.path.join(root, f))
                            result["Finished"].append(f)
                            write_json(result, f"Framework/Fetcher/{name}_result.json")
                        else:
                            logging.error(f"Failed to fetch {f}")
                            result["Failed"].append(f)
                            write_json(result, f"Framework/Fetcher/{name}_result.json")

                except Exception as e:
                    result["Failed"].append(f)
                    result["Warning"].append({f: str(e)})
                    sleep(1.5)
                    write_json(result, f"Framework/Fetcher/{name}_result.json")
                    # 抛出异常
                    print(e)
                    continue


if __name__ == "__main__":
    dotenv.load_dotenv()
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )
    walk_datasets("validate_address", "Experiments/original")
    # fetch_stars("Experiments/original")
