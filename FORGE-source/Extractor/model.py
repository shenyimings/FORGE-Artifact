from langchain_community.llms.ollama import Ollama
from langchain_community.llms.huggingface_pipeline import HuggingFacePipeline
from langchain_community.embeddings.huggingface import HuggingFaceEmbeddings
from langchain_core.pydantic_v1 import BaseModel, Field, SecretStr, root_validator

# from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
from typing import TYPE_CHECKING, Any, Dict, List, Optional


# class ChatHuggingFace:
#     def __init__(
#         self, model_id: str = "Meta-Llama-3-8B", task: str = "text-generation"
#     ):
#         tokenizer = AutoTokenizer.from_pretrained(model_id)
#         model = AutoModelForCausalLM.from_pretrained(model_id)
#         self.pipe = pipeline(task, model=model, tokenizer=tokenizer, max_new_tokens=10)

#     def create_model(self):
#         return HuggingFacePipeline(pipeline=self.pipe)


class ChatOllama:
    def __init__(
        self,
        name: str,
        stop: List[str] = None,
        model_id: str = "llama3:instruct",
        temperature: float = 0.3,
        output_format: str = "json",
        base_url: str = "http://127.0.0.1:11434"
    ):
        if not stop:
            stop = [
                "<|start_header_id|>",
                "<|end_header_id|>",
                "<|eot_id|>",
                "<|end_of_text|>",
            ]
        self.stop = stop
        self.model = Ollama(
            name=name,
            model=model_id,
            stop=stop,
            temperature=temperature,
            num_ctx=8192,
            format=output_format,
            base_url=base_url
        )

    def create_model(self):
        return self.model


# class ChatGPT(ChatOpenAI):
#     name: str
#     openai_api_key: str = Field(default=None, exclude=True)
#     openai_api_base: str = Field(default=None, exclude=True)
#     json_output: Optional[bool] = None
#     model_kwargs: Optional[Dict[str, Dict[str, str]]] = None

#     @classmethod
#     def is_lc_serializable(cls) -> bool:
#         """Return whether this model can be serialized by Langchain."""
#         return True

#     # Pydantic 的 `root_validator` 或 `__post_init__` 方法
#     @root_validator(pre=True)
#     def set_model_kwargs(cls, values):
#         json_output = values.get("json_output")
#         if json_output:
#             values["model_kwargs"] = {"response_format": {"type": "json_object"}}
#         return values

#     @root_validator(pre=True)
#     def set_openai_api_base(cls, values):
#         import os

#         values["openai_api_key"] = os.getenv("OPENAI_API_KEY")
#         values["openai_api_base"] = os.getenv("OPENAI_BASE_URL")
#         return values
