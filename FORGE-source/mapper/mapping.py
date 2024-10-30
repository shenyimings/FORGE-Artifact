"""
1. 接收数据：json,{"title":"vuln title","description":"vuln description"}
2. 读取CWE(cwe_dict.json)
3. 构造CWE树，从最顶层节点开始
4. 从当前层构建prompt
5. 调用workers AI，返回prompt对应的json结果
6. 从json结果中提取下一层的节点
7. 得到最终结果，返回response - json
"""

import logging
import json
import os
import re
import sys
import dotenv
from time import sleep
from typing import List, Dict
from collections import deque
from pydantic import BaseModel
from langchain.prompts import ChatPromptTemplate, BasePromptTemplate
from langchain_core.output_parsers import JsonOutputParser, StrOutputParser

# from langchain_core.messages import AIMessage

sys.path.append("/root/FORGE-Artifact/FORGE-source")
from model import ChatOllama
from CloudflareLLM import CloudflareLLM
from config import Config
from CWE import CWE, CWEHandler


# define an Exception class
class TruncateException(Exception):
    pass


# {"result":["CWE-284","CWE-664"]}
class Classifier(BaseModel):
    level: int = 0
    top_k: int = 2
    vuln_title: str = ""
    vuln_description: str = ""
    prompt_template: BasePromptTemplate = None
    node: List[CWE] = []
    node_count: int = 0
    result_tree: Dict[int, List[CWE]] = {}
    cwe_dict: Dict[str, CWE] = {}
    result: List[CWE] = []

    class Config:
        arbitrary_types_allowed: bool = True

    def parse_result(self, res: str) -> List[CWE]:
        # parse the str("CWE-xxx") to int("xxx")
        cwe_result_list: List[CWE] = []
        regex = re.compile(r"Answer:.*?(CWE-\d+)", re.IGNORECASE)
        handler = CWEHandler(self.cwe_dict)
        handler.regex = regex
        try:
            cwe_strs = handler.cwe_from_string(res)
            if not cwe_strs:
                raise TruncateException("No CWE ID found in response.")
            logging.info("CWE ID found: " + str(cwe_strs))
            cwe_result_list = handler.parse_cwe_list(cwe_strs)
            return cwe_result_list

        except ValueError:

            logging.error(f"Failed to parse CWE ID in {res}")

        return cwe_result_list

    def get_prompt(
        self,
        cur_nodes: List[CWE] = [],
        top_k: int = 2,
    ) -> ChatPromptTemplate:
        self.prompt_template
        show_description = True if len(cur_nodes) <= 15 else False
        cwe_info = ""
        for node in cur_nodes:
            cwe_info = (
                cwe_info
                + "\n"
                + "CWE-"
                + str(node.ID)
                + ": "
                + node.Name
                + "\n\n"
                # + "\nDescription: "
                # + node.Description
            )
            if show_description:
                cwe_info += ": " + node.Description + "\n"

        self.prompt_template = self.prompt_template.partial(
            # output_format='{"result":["CWE-840"]}',
            # top_k=top_k,
            info=cwe_info,
        )
        vuln_info = (
            "\nTitle: "
            + self.vuln_title
            + "\nDescription: "
            + self.vuln_description
            + "\n"
        )
        logging.debug(
            "Invoking for prompt: "
            + str(self.prompt_template.invoke({"vuln": vuln_info}))
        )
        return self.prompt_template

    def classify(self, temperature=0.2):
        self.top_k = 1 if self.level == 0 else 1
        prompt = self.get_prompt(self.node, self.top_k)
        # llm = ChatOllama(
        #     "classify",
        #     model_id="llama3:70b-instruct-q8_0",
        #     temperature=temperature,
        #     base_url="http://localhost:21434",
        # ).create_model()
        account_id = os.getenv("CF_ID")
        api_token = os.getenv("CF_TOKEN")
        llm = CloudflareLLM(
            account_id=account_id,
            api_token=api_token,
            gateway="forge",
            temperature=temperature,
            # max_tokens=2048,
        )
        chain = prompt | llm | StrOutputParser()
        vuln_info = (
            "\nTitle: "
            + self.vuln_title
            + "\nDescription: "
            + self.vuln_description
            + "\n"
        )

        result = chain.invoke({"vuln": vuln_info})
        logging.info("LLM Response: " + str(result))
        last_result = self.result
        self.result = self.parse_result(result)
        # print(self.result,last_result)
        if self.result == last_result:
            logging.info("No new result found, exiting.")
            return

        if self.result:
            self.result_tree[self.level + 1] = [
                "CWE-" + str(res.ID) for res in self.result
            ]
        # for i in self.result:
        choose = ", ".join(["CWE-" + str(i.ID) for i in self.result])
        logging.info("Choose: " + choose)


class VulnerabilityAnalyzer:
    @staticmethod
    def analyze(
        vuln_info: Dict[str, str],
        cwe_dict: Dict[str, CWE],
        prompt_template: BasePromptTemplate,
    ) -> Dict[int, CWE]:
        classifier = Classifier(
            vuln_title=vuln_info["title"],
            vuln_description=vuln_info["description"],
            cwe_dict=cwe_dict,
            prompt_template=prompt_template,
        )

        def bfs_traverse(root: List[CWE]):
            if not root:
                return

            queue = deque(root)
            classifier.result = root
            classifier.level = 0
            classifier.node = root

            while queue:
                classifier.node_count = len(queue)
                logging.debug(
                    f"Level {classifier.level}, count {classifier.node_count}: "
                )
                # DONE: Add exception retry here

                max_retry_times = 3
                attempts = 0
                temperature = 0.2
                while attempts < max_retry_times:
                    try:
                        classifier.classify(temperature=temperature)
                        classifier.node = []
                        sleep(0.6)
                        break
                    except TruncateException as e:
                        temperature += 0.1
                        logging.error(
                            "TruncateException: No CWE ID found in answers, retrying..."
                        )
                        sleep(4 * attempts)
                        continue
                    except Exception as e:
                        attempts += 1
                        temperature += 0.1
                        logging.error(
                            str(e)
                            + "\nError in classify "
                            + classifier.vuln_title
                            + "\n Retrying, times "
                            + str(attempts)
                        )
                        sleep(2**attempts)

                classifier.node = []

                for _ in range(classifier.node_count):
                    node = queue.popleft()
                    if node not in classifier.result:
                        continue

                    if (
                        classifier.level != -100
                    ):  # Change to 0 to exclude first level nodes from second level
                        if (
                            node.Mapping == "Allowed"
                            or node.Mapping == "Allowed-with-Review"
                            or node.Mapping == "Discouraged"
                        ):
                            classifier.node.append(node)

                    for child in node.Child:
                        classifier.node.append(child)
                        queue.append(child)

                next_level = ", ".join(
                    ["CWE-" + str(node.ID) for node in classifier.node]
                )
                logging.info(f"Next level: {next_level}\n")

                # logging.info("\n")
                classifier.level += 1

        initial_cwe_list = [
            cwe_dict["CWE-284"],
            cwe_dict["CWE-435"],
            cwe_dict["CWE-664"],
            cwe_dict["CWE-682"],
            cwe_dict["CWE-691"],
            cwe_dict["CWE-693"],
            cwe_dict["CWE-697"],
            cwe_dict["CWE-703"],
            cwe_dict["CWE-707"],
            cwe_dict["CWE-710"],
        ]
        bfs_traverse(initial_cwe_list)
        logging.debug(vuln_info)
        # classifier.verify()
        return classifier.result_tree


def process_file(file_path: str, context: Config):

    rel_path = os.path.relpath(file_path, context.input_dir)
    company = os.path.dirname(rel_path)
    output_path = os.path.join(context.output_dir, rel_path)

    def save_json(content, path):
        with open(path, "w", encoding="utf8") as outf:
            json.dump(content, outf)

    logging.info("Processing " + file_path + "...")
    with open(file_path, "r", encoding="utf8") as openf:
        vuln_data = json.load(openf)

    if not vuln_data.get("findings", []):
        save_json(vuln_data, output_path)
        context.save_history(file_path)
        return

    for finding in vuln_data["findings"]:
        if finding["description"] == "" or finding["title"] == "":
            continue
        # DONE: Add exception catch here
        try:
            res = VulnerabilityAnalyzer.analyze(
                vuln_info={
                    "title": finding["title"],
                    "description": finding["description"],
                },
                cwe_dict=context.cwe_dict,
            )
            logging.info(finding["title"] + ": " + str(res))
            if res:
                finding["category"] = res

        except Exception as e:
            logging.error(
                str(e) + "\nError in analyze " + file_path + "\n" + finding["title"]
            )

    # filename = os.path.basename(file_path)
    # output_path = os.path.join(os.path.dirname(file_path), "final", filename)
    save_json(vuln_data, output_path)
    context.save_history(file_path)


def process_samples(path: str, context: Config):
    import csv

    all_rows = None
    with open(path, "r", encoding="utf8") as f:
        reader = csv.DictReader(f)
        all_rows = list(reader)
    header = reader.fieldnames
    header.append("category_new")
    data_rows = all_rows

    for i in range(60, min(61, len(data_rows))):
        row = data_rows[i]
        res = VulnerabilityAnalyzer.analyze(
            vuln_info={
                "title": row["title"],
                "description": row["description"],
            },
            cwe_dict=context.cwe_dict,
            prompt_template=context.prompt,
        )
        logging.info(row["title"] + ": " + str(res))
        # save to current csv file
        row["category_new"] = res
        pass

    # 保存修改后的文件
    with open(path + ".csv", "w", encoding="utf-8", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(header)
        for row in data_rows:
            writer.writerow(row.values())


def main():
    logging.basicConfig(
        # filename="mapping.log",
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    dotenv.load_dotenv(".env")
    context = Config(input_dir="source")
    context.get_input_file()
    context.load_cwe()
    context.load_prompt()
    process_samples("Experiments/sample_list.csv", context)
    # context.files = [

    #     "../output/t3/Runtime_Verification/Runtime_Verification-SundaeSwap.json",
    # ]

    # for file_path in context.files:
    #     process_file(file_path, context)


if __name__ == "__main__":

    main()
