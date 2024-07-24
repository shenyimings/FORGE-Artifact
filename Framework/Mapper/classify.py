import logging
import json
import os
import re
from typing import List, Dict
from collections import deque
from pydantic import BaseModel
from langchain.prompts import ChatPromptTemplate, BasePromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from model import ChatOllama
from config import Config
from CWE import CWE


# {"result":["CWE-284","CWE-664"]}
class Classifier(BaseModel):
    level: int = 0
    top_k: int = 2
    vuln_title: str = ""
    vuln_description: str = ""
    node: List[CWE] = []
    node_count: int = 0
    result_tree: Dict[int, List[CWE]] = {}
    cwe_dict: Dict[str, CWE] = {}
    result: List[CWE] = []
    class Config:
        arbitrary_types_allowed: bool = True

    def parse_result(self, res: Dict) -> List[CWE]:
        # parse the str("CWE-xxx") to int("xxx")
        cwe_result_list: List[CWE] = []
        regex = re.compile(r"CWE-(\d+)", re.IGNORECASE)
        for i in res.get("result", []):
            try:
                i = re.sub(regex, r"\1", i)
                if self.cwe_dict.get("CWE-" + i, False):
                    cwe_result_list.append(self.cwe_dict["CWE-" + i])
                    logging.debug("CWE-" + i)
                else:
                    logging.error(f"Failed to find CWE ID: CWE-{i}")
                    continue
            except ValueError:
                logging.error(f"Failed to parse CWE ID: {i}")
                continue
        return cwe_result_list

    def get_prompt(
        self, cur_nodes: List[CWE] = [], top_k: int = 2
    ) -> ChatPromptTemplate:
        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "user",
                    """
You are given a smart contract vulnerability with a title and description. Your task is to map this vulnerability to the top {top_k} most relevant CWE (Common Weakness Enumeration) types level by level based on its title and description. Use the current level of CWE ID, title, and description provided below. Output the result in JSON format as follows:\n```json\n{output_format}```
CWE types reference:\n{info}

Now, user input:{vuln}

Tasks: 
1. Analyze the given input vulnerability title and description. 
2. Match the vulnerability to the top {top_k} most relevant CWE types provided above. 
3. Output the result in JSON format.""",
                )
            ]
        )
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

        prompt = prompt.partial(
            output_format='{"result":["CWE-840"]}',
            top_k=top_k,
            info=cwe_info,
        )
        vuln_info = (
            "\nTitle: "
            + self.vuln_title
            + "\nDescription: "
            + self.vuln_description
            + "\n"
        )
        logging.debug("Invoking for prompt: " + str(prompt.invoke({"vuln": vuln_info})))
        return prompt

    def verify(self):
        if len(self.result_tree) == 1:
            logging.info(self.result_tree[1])
            return self.result_tree[1]
        prompt = ChatPromptTemplate.from_messages(
            [
                # ("system","You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability. You are designed to output in json."),
                (
                    "user",
                    """
Here is a hierarchical CWE tree classification result in the following format:

{input_result}

Each key represents a classification level, where 1 is the top level and 5 or more is the deeper level. The corresponding values are arrays of CWE IDs classified at that level. 
CWE Information:
{CWE}

Task:
Using the hierarchical classification input, evaluate the given CWE IDs and determine the most accurate, specific, and as granular as possible single CWE ID within the provided tree structure.
Your response should be a JSON object with the most accurate CWE ID, ensuring it is the most specific classification possible based on the hierarchical input.
Example:
{output_example}""",
                )
            ]
        )
        cwe_info = ""
        for level in self.result_tree.keys():
            node_str_list = self.result_tree[level]
            for node_str in node_str_list:
                node = self.cwe_dict[node_str]
                cwe_info = (
                    cwe_info
                    + "\n"
                    + "CWE-"
                    + str(node.ID)
                    + ": "
                    + node.Name
                    + "\nDescription: "
                    + node.Description
                    + "\n\n"
                )
        prompt = prompt.partial(CWE=cwe_info, output_example=r'{result:"CWE-840"}')
        ollama = ChatOllama(
            "verify",
            model_id="llama3:70b-instruct-q8_0",
            temperature=0,
            base_url="http://localhost:21434",
        ).create_model()
        chain = prompt | ollama | JsonOutputParser()
        result = chain.invoke({"input_result": self.result_tree})
        logging.info("Verified: " + str(result))
        return result.get("result")

    def classify(self,temperature=0.2):
        self.top_k = 1 if self.level == 0 else 1
        prompt = self.get_prompt(self.node, self.top_k)
        ollama = ChatOllama(
            "classify",
            model_id="llama3:70b-instruct-q8_0",
            temperature=temperature,
            base_url="http://localhost:21434",
        ).create_model()
        chain = prompt | ollama | JsonOutputParser()
        vuln_info = (
            "\nTitle: "
            + self.vuln_title
            + "\nDescription: "
            + self.vuln_description
            + "\n"
        )

        result = chain.invoke({"vuln": vuln_info})
        logging.debug("LLM Response: " + str(result))
        last_result = self.result
        self.result = self.parse_result(result)
        # print(self.result,last_result)
        if self.result == last_result:
            logging.debug("No new result found, exiting.")
            return

        if self.result:
            self.result_tree[self.level + 1] = [
                "CWE-" + str(res.ID) for res in self.result
            ]
        for i in self.result:
            logging.debug("Choose: " + str(i.ID))

class VulnerabilityAnalyzer:
    @staticmethod
    def analyze(vuln_info: Dict[str, str], cwe_dict: Dict[str, CWE]) -> Dict[int, CWE]:
        classifier = Classifier(
            vuln_title=vuln_info["title"],
            vuln_description=vuln_info["description"],
            cwe_dict=cwe_dict,
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
                        break
                    except Exception as e:
                        attempts += 1
                        temperature+=0.1
                        logging.error(str(e)+"\nError in classify "+classifier.vuln_title+"\n Retrying, times "+str(attempts))
                
                
                classifier.node = []

                for _ in range(classifier.node_count):
                    node = queue.popleft()
                    if node not in classifier.result:
                        continue

                    if (
                        classifier.level != -100
                    ):  # Change to 0 to exclude first level nodes from second level
                        classifier.node.append(node)

                    for child in node.Child:
                        classifier.node.append(child)
                        queue.append(child)

                for node in classifier.node:
                    logging.debug(f"Next level: CWE-{node.ID},")

                logging.debug("\n")
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


def main():
    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S",
                        )
    config = Config(input_dir="source")
    config.get_input_file()
    config.load_cwe()
    # config.files = [
        
    #     "../output/t3/Runtime_Verification/Runtime_Verification-SundaeSwap.json",
    # ]

    for file_path in config.files:
        process_file(file_path, config)
        


def process_file(file_path: str, config: Config):
    

    rel_path = os.path.relpath(
        file_path, config.input_dir)
    company = os.path.dirname(rel_path)
    output_path = os.path.join(
        config.output_dir, rel_path)

    def save_json(content,path):
        with open(path, "w", encoding="utf8") as outf:
            json.dump(content, outf)

    

    logging.info("Processing "+file_path+"...")
    with open(file_path, "r", encoding="utf8") as openf:
        vuln_data = json.load(openf)

    if not vuln_data.get("findings", []):
        save_json(vuln_data,output_path)
        config.save_history(file_path)
        return

    for finding in vuln_data["findings"]:
        if finding["description"]=="" or finding["title"]=="":
            continue
        # DONE: Add exception catch here
        try:
            res = VulnerabilityAnalyzer.analyze(
                vuln_info={
                    "title": finding["title"],
                    "description": finding["description"],
                },
                cwe_dict=config.cwe_dict,
            )
            logging.info(finding["title"]+": " + str(res))
            if res:
                finding["category"] = res
            
        except Exception as e:
            logging.error(str(e)+"\nError in analyze "+ file_path +"\n"+finding["title"])
    
    # filename = os.path.basename(file_path)
    # output_path = os.path.join(os.path.dirname(file_path), "final", filename)
    save_json(vuln_data,output_path)
    config.save_history(file_path)
    


if __name__ == "__main__":
    
    main()
