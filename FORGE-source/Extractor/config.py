from langchain_core.pydantic_v1 import BaseModel


class Config(BaseModel):
    history: str = "history.json"
    output_dir: str = "./output/t3"
    embedding_model: str = "BAAI/bge-base-en-v1.5"
    embedding_kwargs: dict = {"device": "cuda"}
    embedding_show_progress: bool = False
    base_url: str = "http://127.0.0.1:23333"
    summary_model: str = "llama3:70b-json-q8_0"
    classify_model: str = "llama3:70b-json-q8_0"
    summary_model_temperature: float = 0.3
    classify_model_temperature: float = 0.3
    max_retry_times: int = 3
    toc_search_type: str = "similarity"
    info_search_type: str = "mmr"
    toc_query_k: int = 2
    info_query_k: int = 3
    chunk_size: int = 1536
    chunk_overlap: int = 64
    split_literal = [
        ("#", "H1"),
        ("##", "H2"),
        ("###", "H3"),
        ("####", "H4"),
        ("#####", "H5"),
    ]
