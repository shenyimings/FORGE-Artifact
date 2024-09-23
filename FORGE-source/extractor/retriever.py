from document import PDFDocumentProcessor
from langchain_core.pydantic_v1 import BaseModel, Field, SecretStr, root_validator
from langchain_core.vectorstores import VectorStoreRetriever, VectorStore
from typing import (
    TYPE_CHECKING,
    Any,
    Callable,
    ClassVar,
    Collection,
    Dict,
    Iterable,
    List,
    Optional,
    Tuple,
    Type,
    TypeVar,
)


class Retriever(VectorStoreRetriever):
    """Retriever class for VectorStore."""

    name: str = "Retriever"
    doc_processor: PDFDocumentProcessor
    vectorstore: VectorStore = None
    """VectorStore to use for retrieval."""
    search_type: str = "similarity"
    """Type of search to perform. Defaults to "similarity"."""
    search_kwargs: dict = Field(default={"k": 3})
    """Keyword arguments to pass to the search function."""
    include_toc: bool = True
    allowed_search_types: ClassVar[Collection[str]] = (
        "similarity",
        "similarity_score_threshold",
        "mmr",
    )

    @root_validator()
    def check_include_toc(cls, values):
        """Ensure that include_toc is only set to True if the vectorstore has a TOC."""
        include_toc = values.get("include_toc")
        if not include_toc:
            if values["doc_processor"].toc_metadata:
                filter = {
                    values["doc_processor"].splitter_string[-1],
                    {
                        "$ne": values["doc_processor"].toc_metadata[
                            values["doc_processor"].splitter_string[-1]
                        ]
                    },
                }
                values["search_kwargs"] = filter
        return values

    @root_validator(pre=False)
    def check_vector_db(cls, values):
        """Ensure that the VectorStore has been created."""
        if not values["vectorstore"]:
            values["vectorstore"] = values["doc_processor"].db
        if not values["vectorstore"]:
            raise ValueError("VectorStore not found.")
        return values


# import logging

# logging.basicConfig(level=logging.INFO)
# doc = PDFDocumentProcessor(
#     "sample\CertiK Audit Report 280321.pdf", embedding_model="BAAI/bge-base-en-v1.5"
# )
# retriever = Retriever(doc_processor=doc)
# res = retriever.invoke("Table of Contents or all findings list", k=5, include_toc=True)
# for doc in res:
#     print(doc, "\n")
