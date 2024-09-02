import os
import re
import csv
import json
import requests
import logging
from typing import Literal


class Addr_Fetcher:
    """
    input an address
    determine the type of the address by check the csv list(ETH or BSC)
    bsc-verified-contract-address.csv
    eth-verified-contract-address.csv
    """

    def __init__(self):
        # self.address = address
        # self.chain: Literal["bsc", "eth", "unknown"] = "unknown"
        # self.type: Literal["EOA", "contract", "unknown"] = "unknown"
        # self.get_verified_address()
        self.bsc_token = os.getenv("BSC_TOKEN")
        self.eth_token = os.getenv("ETH_TOKEN")
        self.polygon_token = os.getenv("POLYGON_TOKEN")
        self.addr_parser = r"\b0x[a-fA-F0-9]{40}\b"

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
        result = {}
        # try parse to json
        try:
            if source_code.startswith("{{"):
                source_code = source_code.strip()[1:-1]
            data = json.loads(source_code)
            if data.get("sources", False):
                result = data["sources"]
                return result

            else:
                result = data
                # print(result)
                return result
        except json.JSONDecodeError:

            result[contract_name + ".sol"] = {"content": source_code}
            return result

    def call_api(self, address: str, chain: Literal["bsc", "eth", "polygon"]):
        params = {
            "module": "contract",
            "action": "getsourcecode",
            "address": address,
        }
        if chain == "polygon":
            base_url = "https://api.polygonscan.com/api"
            params["apikey"] = self.polygon_token
        elif chain == "bsc":
            base_url = "https://api.bscscan.com/api"
            params["apikey"] = self.bsc_token
        elif chain == "eth":
            base_url = "https://api.etherscan.io/api"
            params["apikey"] = self.eth_token

        response = requests.get(base_url, params=params)
        if response.status_code == 200:

            data = response.json()
            data = data["result"]
            if len(data) > 1:
                exit("Multiple contracts found!")
            if not data[0].get("SourceCode", False):
                return None
            sourceCode = self.parse_code(data[0]["ContractName"], data[0]["SourceCode"])
            return {
                "chain": chain,
                "contractName": data[0]["ContractName"],
                "compilerVersion": data[0]["CompilerVersion"],
                "sourceCode": sourceCode,
            }
        else:
            # 处理错误情况
            print(f"Failed to get data, status code: {response.status_code}")
            return None

    def fetch_code(self, address, output_dir: str) -> dict:
        chain_list = ["eth", "bsc", "polygon"]
        for chain in chain_list:
            data = self.call_api(address, chain)
            if data:
                # save to local
                for sol in data["sourceCode"].keys():
                    if sol.split(".")[-1] != "sol":
                        sol += ".sol"
                    if not data["contractName"]:
                        data["contractName"] = "unknown"
                    os.makedirs(
                        os.path.dirname(
                            os.path.join(output_dir, data["contractName"], sol)
                        ),
                        exist_ok=True,
                    )
                    with open(
                        os.path.join(output_dir, data["contractName"], sol),
                        "w",
                        encoding="utf8",
                    ) as f:
                        f.write(data["sourceCode"][sol]["content"])
                        pass
                data.pop("sourceCode")
                data["contractPath"] = os.path.join(output_dir, data["contractName"])
                return data

    def get_verified_address(self):
        # check if the address is a contract and which chain it belongs to
        self.eth_data = []
        self.bsc_data = []
        with open(r"Framework\Fetcher\eth-verified-contract-address.csv", "r") as f:
            csv_reader = csv.DictReader(f)
            for row in csv_reader:
                self.eth_data.append(row["ContractAddress"].lower())
        with open(r"Framework\Fetcher\bsc-verified-contract-address.csv", "r") as f:
            csv_reader = csv.DictReader(f)
            for row in csv_reader:
                self.bsc_data.append(row["ContractAddress"].lower())
