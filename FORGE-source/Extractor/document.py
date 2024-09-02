import re
import fitz
import logging
# import pdf4llm
import pymupdf4llm
from langchain_community.embeddings.huggingface import HuggingFaceEmbeddings
from langchain_core.documents import Document
from langchain_text_splitters import (
    MarkdownHeaderTextSplitter,
    RecursiveCharacterTextSplitter,
)
from langchain_community.vectorstores.chroma import Chroma
from chromadb.config import Settings
from typing import TYPE_CHECKING, Any, Tuple, List, Optional
from config import Config


class PDFDocumentProcessor:
    def __init__(self, pdf_path: str, config: Config, extension_name: str = "pdf"):
        self.pdf_path = pdf_path
        self.chunk_size = config.chunk_size
        self.chunk_overlap = config.chunk_overlap
        self.split_literal = config.split_literal
        self.embedding_model = config.embedding_model
        self.embedding_kwargs = config.embedding_kwargs
        self.collection_name = self.get_collection_name(pdf_path)
        self.embedding_show_progress = config.embedding_show_progress
        self.toc_metadata = {}
        if str.lower(extension_name) == "pdf":
            md_text = self.merge_lines(
                self.str_preprocess(pymupdf4llm.to_markdown(pdf_path))
            )
            # md_text =pymupdf4llm.to_markdown(pdf_path)
            
        elif str.lower(extension_name) == "md":
            with open(pdf_path, "r", encoding="utf8") as f:
                md_text = f.read()
        else:
            logging.error("Unsupported file extension!")
        doc_len = len(md_text.split())
        if doc_len < 1024:
            logging.info("Small document detected: "+ str(doc_len))
            self.small_doc = True
        else:
            self.small_doc = False
        logging.info("Splitting text...")
        self.txt_splitter = RecursiveCharacterTextSplitter(
            chunk_size=config.chunk_size, chunk_overlap=config.chunk_overlap
        )
        self.md_splitter = MarkdownHeaderTextSplitter(
            headers_to_split_on=config.split_literal, strip_headers=False
        )
        self.documents = self.txt_splitter.split_documents(
            self.md_splitter.split_text(md_text)
        )
        # print(self.documents)
        self._create_vector_db()

    def _create_vector_db(self, db_persist_dir: str = None) -> None:
        # Alibaba-NLP/gte-base-en-v1.5
        # BAAI/bge-base-en-v1.5
        self.embedder = HuggingFaceEmbeddings(
            model_name=self.embedding_model,
            model_kwargs=self.embedding_kwargs,
            show_progress=self.embedding_show_progress,
        )
        if db_persist_dir:

            self.db = Chroma.from_documents(
                self.documents,
                self.embedder,
                collection_name=self.collection_name,
                persist_directory=db_persist_dir,
                client_settings=Settings(anonymized_telemetry=False),
            )

        else:
            self.db = Chroma.from_documents(
                self.documents,
                self.embedder,
                collection_name=self.collection_name,
                client_settings=Settings(anonymized_telemetry=False),
            )

    def _delete_collection(self):
        self.db.delete_collection()

    def str_preprocess(self, doc_text: str):
        logging.info("Preprocessing document...")
        # 去除所有零宽断言/隐藏编码等 \u200c等
        doc_text = doc_text.replace("**\u200c**", "")
        doc_text = doc_text.replace("\u202c", "")
        doc_text = doc_text.replace("\u202d", "")
        return doc_text.replace("\u200c", "")

    def merge_lines(self, doc_text: str):
        logging.info("Merging heading lines...")
        pattern2 = r"(##.*)\n+(##\s*)(.*)"
        pattern3 = r"(###.*)\n+(###\s*)(.*)"
        merged_text = re.sub(pattern2, r"\1 \3", doc_text, flags=re.MULTILINE)
        return re.sub(pattern3, r"\1 \3", merged_text, flags=re.MULTILINE)

    def get_collection_name(self, pdf_path):
        "使用pdf_path生成collection_name"
        return "audit-reports"
        # return "pdf_" + pdf_path.split("/")[-1].split(".")[0][:30]

    def mmr_search(self, query, k, include_toc=True) -> List[Document]:
        if include_toc:
            filter = None
        else:
            filter = None
            if self.toc_metadata.get(self.split_literal[-1], False):

                filter = {
                    self.split_literal[-1],
                    {"$ne": self.toc_metadata[self.split_literal[-1]]},
                }
                logging.info(str(filter))

        return self.db.max_marginal_relevance_search(query, k=k, filter=filter)

    def merge_documents(self, pages: List[Document]):
        content = "\n".join([page.page_content for page in pages])
        page_nums = [page.metadata.get("page", None) for page in pages]
        total_page = pages[0].metadata.get("total_pages", 0)

        return Document(
            page_content=content,
            metadata={"page_nums": page_nums, "total_pages": total_page},
        )

    def get_page_content(self, page_num) -> str:
        for doc in self.documents:
            if doc.metadata["page"] == page_num:
                return doc.page_content

    def extend_document_by_page(self, doc: Document):
        page_nums = doc.metadata.get("page_nums", [])
        total_page = doc.metadata.get("total_pages", None)
        if page_nums[0] + 1 not in page_nums:
            next_page = page_nums[0] + 1
        elif page_nums[0] + 1 in page_nums:
            next_page = page_nums[0] + 1
            while next_page in page_nums:
                next_page += 1
        if next_page < total_page:
            doc.page_content += "\n" + self.get_page_content(next_page)
            doc.metadata["page_nums"].append(next_page)
            return True
        else:
            return False


# logging.basicConfig(level=logging.INFO)
# test = PDFDocumentProcessor(
#     "./sample/ConsenSys_Diligence-Skale_Token.pdf",
#     embedding_model="./bge-base-en-v1.5",
# )

# # test._create_vector_db()
# # print(test.documents)
# res = test.mmr_search("Table of Contents or all findings list", k=5, include_toc=False)
# test.db.as_retriever()
# print(res)
