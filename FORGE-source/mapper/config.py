"""
负责处理进度情况和输出
"""

import os
import re
import json
import pickle
from pydantic import BaseModel, Field, SecretStr, root_validator
from dataclasses import dataclass, field
from langchain.prompts import ChatPromptTemplate, BasePromptTemplate
from typing import List, Dict

@dataclass
class Message:
    role: str
    content: str

    def to_tuple(self):
        return (self.role, self.content)


@dataclass
class Messages:

    messages: list[tuple[str, str]] = field(default_factory=list)

    def add(self, message: Message):
        self.messages.append(message.to_tuple())

    def load_from_file(
        self, path: str, prompt_name: str = "prompt"
    ) -> BasePromptTemplate:
        with open(path, "r", encoding="utf8") as openf:
            data = json.load(openf)
            for m in data[prompt_name]:
                self.add(Message(m["role"], m["content"]))
        return ChatPromptTemplate.from_messages(self.messages)



class Config(BaseModel):
    """Config class for Classifier."""

    arbitrary_types_allowed: bool = True
    """Allow arbitrary types in the model."""
    input_dir: str = Field(
        description="The input directory with vulns.",
    )
    output_dir: str = Field(
        default="FORGE-source/mapper/output",
        description="The output directory with vulns.",
    )
    files: List[str] = Field(
        default=[],
        description="The list of files in the input directory.",
    )
    cwe_path: str = Field(
        default="FORGE-source/mapper/cwe_dict.pkl",
        description="The path to the CWE pickle file.",
    )
    cwe_dict: Dict = Field(
        default={},
        description="CWE information.",
    )
    history_path: str = Field(
        default="classify_history.json", description="The path to the history file."
    )
    history: dict = Field(
        default={},
        description="The result tree.",
    )
    prompt_path: str = Field(
        default="FORGE-source/mapper/prompts/map_prompt.json",
        description="The path to the prompt file.",
    )
    prompt: BasePromptTemplate = Field(default=None, description="The prompt template.")

    def load_prompt(self):
        self.prompt = Messages().load_from_file(self.prompt_path, "few-shot")

    def load_cwe(self):
        with open(self.cwe_path, "rb") as f:
            self.cwe_dict = cwe_dict = pickle.load(f)

    def load_history(self):
        if os.path.exists(self.history_path):
            with open(self.history_path, "r") as f:
                self.history = json.load(f)

    def get_input_file(self) -> List[str]:
        self.load_history()
        for root, dirs, files in os.walk(self.input_dir):
            for file in files:

                if not file.endswith(".json"):
                    continue

                rel_path = os.path.relpath(os.path.join(root, file), self.input_dir)
                parent_dir = os.path.dirname(rel_path)
                new_dir = os.path.join(self.output_dir, parent_dir)
                if os.path.join(root, file) in self.history.get("Classified", []):
                    # print("continue")
                    continue

                # print(os.path.join(root, file))
                # print(new_dir)

                os.makedirs(new_dir, exist_ok=True)
                self.files.append(os.path.join(root, file))

    def save_history(self, filename: str):

        if self.history.get("Classified", False):
            self.history["Classified"].append(filename)
        else:
            self.history["Classified"] = [filename]
        # print(self.history)
        with open(self.history_path, "w") as f:
            json.dump(self.history, f)


# config = Config(input_dir="output")
# config.get_input_file()
# print(config.files)
# for f in config.files:
#     print(f)
#     config.save_history(f)
