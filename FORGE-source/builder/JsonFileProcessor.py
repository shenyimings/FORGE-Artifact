import os
import sys
import logging
from time import sleep
from tqdm import tqdm

sys.path.append(os.getcwd())
from typing import Callable, Literal, Any, List, Union
from builder.utils import (
    StopIteration,
    read_json,
    write_json,
    log_to_file,
    get_log_status,
    path_handle,
)
from builder.GitFetcher import GitFetcher
from builder.AddrFetcher import AddrFetcher


class JsonFileProcessor:
    def __init__(
        self,
        log_path: str = f"builder/logs/builder_process.json",
        dataset_path: str = f"../Experiments/contracts",
    ):
        self.log_path = log_path
        self.dataset_path = dataset_path

    def fetch_from_chain(self, addr: str, output_path: str):
        fetcher = AddrFetcher()
        addr_list = fetcher.parse_address(addr)
        isSuccessful = False
        project_path = {}
        chain = ""
        compilerVersion = set()
        for addr in addr_list:
            # print(addr)

            res = fetcher.fetch_code(addr, output_path)
            # print(res)
            if not res:
                continue
            isSuccessful = True
            # print(res["contractName"])
            chain = res["chain"]
            compilerVersion.add(res["compilerVersion"])
            project_path[res["contractName"]] = res["contractPath"]
        if isSuccessful:
            return chain, list(compilerVersion), project_path
        return None

    def fetch_from_github(self, url: str, commit_hash: str, output_path: str) -> str:
        fetcher = GitFetcher()
        fetcher.auth()
        parsed_url = fetcher.parse_url(url, commit_hash)
        if not parsed_url:
            return None
        repo_path = f"{output_path}/{parsed_url.repo}"
        res = fetcher.clone_repo(
            url=parsed_url,
            output_path=repo_path,
        )
        if res:
            # print(f"Checking out to {parsed_url.branch}")
            fetcher.check_out(repo_path, commit_id=parsed_url.branch)
            return repo_path
        return None

    def walk_dir(self, dir_path, action: Callable[[str, str], Any]):
        # read all json files
        for root, dirs, files in os.walk(dir_path):
            for file in tqdm(files):
                if file.endswith(".json"):
                    # get the filename
                    try:
                        base_name = os.path.basename(file).split(".")[0]
                        action(os.path.join(root, file), base_name)
                    except StopIteration:
                        logging.info("Process decided to stop.")
                        return
                    except Exception as e:
                        logging.error(f"Error in {os.path.join(root, file)}:\n {e}")
                        sleep(3)
                        continue

    def fetch_action(self, file_path: str, base_name: str):

        log_info = get_log_status(self.log_path)
        if file_path in log_info["info"] or file_path in log_info["error"]:
            return

        data = read_json(file_path)
        if data["project_info"].get("project_path", None):
            # if data["project_info"].get("compilerVersion", None):
            #     # change compilerVersion to compiler_version
            #     data["project_info"]["compiler_version"] = data["project_info"].pop(
            #         "compilerVersion"
            #     )
            #     write_json(data, file_path)
            log_to_file(self.log_path, "info", file_path)
            return
        if data["project_info"].get("address", "N/A") == "N/A":
            if data["project_info"].get("url", "N/A") == "N/A":
                return
            if not data["project_info"].get("is_exists", False):
                return
        address = data["project_info"]["address"]
        output_path = os.path.join(self.dataset_path, base_name)
        # output_path = output_path.strip("../")
        if address and address != "N/A":
            res = self.fetch_from_chain(address, output_path)
            if res:
                chain = res[0]
                compiler_version = res[1]
                project_path = res[2]
                for key in project_path:
                    project_path[key] = path_handle(file_path, project_path[key])
                data["project_info"]["chain"] = chain
                data["project_info"]["compiler_version"] = compiler_version
                data["project_info"]["project_path"] = project_path
                write_json(data, file_path)
                log_to_file(self.log_path, "info", file_path)
                return
            logging.error(f"Failed to fetch from chain: {file_path},{address}")
            log_to_file(self.log_path, "error", file_path)
        url = data["project_info"]["url"]
        commit_hash = data["project_info"].get("commit_hash", "")
        if commit_hash == "N/A":
            commit_hash = ""
        if url and url != "N/A" and data["project_info"].get("is_exists", False):
            res = self.fetch_from_github(url, commit_hash, output_path)
            if res:
                data["project_info"]["project_path"] = path_handle(file_path, res)
                write_json(data, file_path)
                log_to_file(self.log_path, "info", file_path)
                return
            logging.error(f"Failed to fetch from github: {file_path},{url}")
            log_to_file(self.log_path, "warning", file_path)
        return

        # url = data["project_info"]["url"]

    def check(self):
        return os.path.exists(self.file_path)


# json_processor = JsonFileProcessor()
# json_processor.walk_dir("../Experiments/original", json_processor.fetch_action)
