import requests
from typing import Literal


def call_api(address: str, chain: Literal["bsc", "eth"] = "eth"):
    base_url = (
        "https://api.bscscan.com/api"
        if chain == "bsc"
        else "https://api.etherscan.io/api"
    )
    params = {
        "module": "contract",
        "action": "getsourcecode",
        "address": address,
        "apikey": "YH3T1VGUFAS1IXCFSJXCNSV6VJQ7D97JEW",
    }
    response = requests.get(base_url, params=params)
    if response.status_code == 200:

        data = response.json()
        data = data["result"][0]
        return data["SourceCode"]

    else:
        # 处理错误情况
        print(f"Failed to get data, status code: {response.status_code}")


data = call_api("0xb09A1410cF4C49F92482F5cd2CbF19b638907193")
data: str = data.strip()[1:-1]
# data = data.replace("\\n", "\\")
import json

a = json.loads(data)
print(a)
