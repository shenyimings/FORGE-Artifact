import logging
import prompt
from retriever import Retriever
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.language_models import BaseLanguageModel
from langchain_core.pydantic_v1 import BaseModel
from langchain_core.runnables import RunnablePassthrough
from langchain_core.tracers.context import tracing_v2_enabled
from langchain_core.output_parsers import JsonOutputParser


class Query(BaseModel):

    chat_model: BaseLanguageModel
    retriever: Retriever
    output_parser: JsonOutputParser = JsonOutputParser()
    # retry_times: int = 3

    # @retry(stop_max_attempt_number=3, wait_fixed=366)
    def call_query(
        self,
        name: str,
        retriever_prompt: str,
        chat_prompt: ChatPromptTemplate,
        output_format: BaseModel,
    ) -> BaseModel:

        # self.output_parser.pydantic_object = output_format
        # relevant_docs = self.retriever.with_config(
        #     run_name="retrieve_documents"
        # ).invoke(retriever_prompt)
        chat_prompt = chat_prompt.partial(
            output_format=output_format.generate_example()
        )
        # print(retriever_prompt)
        # print(chat_prompt)
        logging.debug(self.retriever.invoke(retriever_prompt))
        chain = (
            self.retriever
            | {"relevant_docs": RunnablePassthrough()}
            | chat_prompt
            | self.chat_model
            | self.output_parser
        ).with_config(run_name=name)
        logging.info("Calling Query...")
        llm_res = chain.invoke(retriever_prompt)
        # print(llm_res)
        return output_format.parse_obj(llm_res)


# dotenv.load_dotenv()
# logging.basicConfig(level=logging.INFO)
# # os.environ["LANGCHAIN_API_KEY"] = "ls__46a7c68ac2d94629a5dba3f1a723a994"

# doc = PDFDocumentProcessor(
#     "sample\CertiK Audit Report 280321.pdf", embedding_model="BAAI/bge-base-en-v1.5"
# )
# retriever = Retriever(doc_processor=doc)
# query = Query(
#     chat_model=ChatOllama("query").create_model(),
#     retriever=retriever,
#     output_parser=JsonOutputParser(),
#     retry_times=1,
# )

# example_query = "SVL-02 No Entrance Fees When Vault Is Empty"
# res = query.call_query(
#     name=example_query,
#     retriever_prompt=example_query,
#     chat_prompt=prompt.jsonify_prompt.partial(query=example_query),
#     output_format=prompt.Finding,
# )

# print(res)


class TocQuery(Query):

    # DONE: Add results from hybrid search types
    # TODO: When toc=[], mark invalid metadata and search again
    def call_query(
        self,
        name: str,
        retriever_prompt: str,
        chat_prompt: ChatPromptTemplate,
        output_format: BaseModel,
    ) -> BaseModel:

        # self.output_parser.pydantic_object = output_format
        # relevant_docs = self.retriever.with_config(
        #     run_name="retrieve_documents"
        # ).invoke(retriever_prompt)
        chat_prompt = chat_prompt.partial(
                output_format=output_format.generate_example()
        )
        if self.retriever.doc_processor.small_doc:
            toc_hyde = self.retriever.doc_processor.documents
        else:

            # print(retriever_prompt)
            # print(chat_prompt)
            toc_hyde = self.retriever.invoke(retriever_prompt)
            self.retriever.search_kwargs.update({"k": 2})
            self.retriever.search_type = "mmr"
            toc_direct = self.retriever.invoke("Table of contents, audit overview, all finding lists and summary of findings.")

            for doc_direct in toc_direct:
                if doc_direct not in toc_hyde:
                    toc_hyde.append(doc_direct)
            # print(len(toc_hyde))
        logging.debug(toc_hyde)
        chain = (
            chat_prompt
            | self.chat_model
            | self.output_parser
        ).with_config(run_name=name)
        logging.info("Calling Query...")
        llm_res = chain.invoke({"relevant_docs": toc_hyde})
        # print(llm_res)
        return output_format.parse_obj(llm_res)
    # TODO: Read different hyde prompts for different companies from configuration
    def get_doc_toc(
        self,
        retriever_prompt="""## Table of Contents  
Table of Contents  
Executive Summary  
Introduction  
Disclaimer  
List of Findings  
A01. Minting of unlimited number of sundae tokens  
A02. Accumulation of rounding errors when exchanging old liquidity tokens for new
liquidity tokens  
A03. Any tokens with the currency symbol as the hash of poolMintingPolicyContract
can be minted... """,
        search_type: str = "mmr",
        k=5,
    ) -> prompt.FindingShortList:
        self.retriever.search_kwargs.update({"k": k})
        self.retriever.search_type = search_type
        # print(self.retriever.invoke(retriever_prompt))
        return self.call_query(
            name="Get Document TOC by hybrid methods",
            retriever_prompt=retriever_prompt,
            chat_prompt=prompt.get_toc_prompt,
            output_format=prompt.FindingShortList,
        )
        


class ClassifyQuery(Query):

    # @retry(stop_max_attempt_number=3)
    def call_query(
        self,
        name: str,
        title: str,
        description: str,
        chat_prompt: ChatPromptTemplate,
        output_format: BaseModel,
    ) -> BaseModel:

        self.output_parser.pydantic_object = output_format
        chain = (chat_prompt | self.chat_model | self.output_parser).with_config(
            run_name=name
        )
        llm_res = chain.invoke(
            {
                "output_format": output_format.generate_example(),
                "title": title,
                "description": description,
            }
        )
        return output_format.parse_obj(llm_res)

    # @retry(stop_max_attempt_number=3)
    def get_and_set_category(self, finding: prompt.Finding) -> prompt.Category:
        # TODO: first get pilliar category and then get subcategory
        logging.info("Classifying Finding...")
        chat_prompt = prompt.get_category_prompt.partial(
            knowledge="Common Weakness Enumeration (CWE) is a community-developed list of common software and hardware weaknesses."
        )
        return self.call_query(
            name="Get Category",
            title=finding.title,
            description=finding.description,
            chat_prompt=chat_prompt,
            output_format=prompt.Category,
        )
        # return res.category


class FindingQuery(Query):
    classify_model: BaseLanguageModel

    def _get_finding(
        self,
        index: int,
        finding_title: str,
        max_retry_times=3,
    ):

        finding_without_category = self.call_query(
            name="Get Finding Information",
            retriever_prompt=finding_title,
            chat_prompt=prompt.jsonify_prompt.partial(query=finding_title),
            output_format=prompt.Finding,
        )
        finding_without_category.id = index
        logging.debug(finding_without_category)
        return finding_without_category
        if finding_without_category.category:
            finding_without_category.id = index
            logging.info(
                f"Finding {index}: {finding_title} already has a category: {str(finding_without_category.category)}"
            )
            return finding_without_category
        get_category = ClassifyQuery(
            chat_model=self.classify_model,
            output_parser=self.output_parser,
            retriever=self.retriever,
        )
        retry_times = max_retry_times
        while retry_times > 0:
            try:
                category_res = get_category.get_and_set_category(
                    finding_without_category
                )
                break
            except Exception as e:
                logging.error("Error: " + str(e) + ", retry_times:" + str(retry_times))
                category_res = prompt.Category(category=[])
                retry_times -= 1
                continue

        finding = finding_without_category
        finding.category = category_res.category
        finding.id = index
        print(finding.json())
        return finding

    def get_doc_findings(
        self,
        toc_list: prompt.FindingShortList,
        k=2,
        max_retry_times=3,
        search_type: str = "mmr",
    ) -> list[prompt.Finding]:
        # TODO: 此处添加并发
        self.retriever.search_type = search_type
        self.retriever.search_kwargs.update({"k": k})
        findings = []
        for i, finding_title in enumerate(toc_list.toc):
            retry_times = max_retry_times
            while retry_times > 0:
                try:
                    logging.info(f"Analyzing finding {i}: {finding_title}...")
                    findings.append(
                        self._get_finding(
                            i, finding_title, max_retry_times=max_retry_times
                        )
                    )
                    break
                except Exception as e:
                    logging.error("Error: " + str(e))
                    self.chat_model.temperature = (
                        self.chat_model.temperature + 0.1
                    ) % 0.75
                    retry_times -= 1
                    continue
            # try:
            #     logging.info(f"Analyzing finding {i}: {finding_title}...")
            #     findings.append(self._get_finding(i, finding_title, k))
            # except Exception as e:
            #     logging.error("Error: " + str(e))
            #     findings.append(self._get_finding(i, finding_title, k))
            #     continue

        return findings


class InfoQuery(Query):

    def get_project_info(self, k=2) -> prompt.ProjectInfo:
        self.retriever.search_kwargs.update({"k": k})
        return self.call_query(
            name="Get Project Information",
            retriever_prompt="Audited project information, including github repo url, commit hash and on-chain address",
            chat_prompt=prompt.get_info_prompt,
            output_format=prompt.ProjectInfo,
        )


# from model import ChatOllama
# from document import PDFDocumentProcessor
# from retriever import Retriever
# import logging

# logging.basicConfig(level=logging.INFO)
# test = FindingQuery(
#     chat_model=ChatOllama("query", temperature=0.1).create_model(),
#     classify_model=ChatOllama("query", temperature=0.1).create_model(),
#     retriever=Retriever(
#         doc_processor=PDFDocumentProcessor(
#             "sample\CertiK Audit Report 280321.pdf",
#             embedding_model="BAAI/bge-base-en-v1.5",
#         ),
#     ),
#     output_parser=JsonOutputParser(),
# )

# test.get_doc_findings(prompt.FindingShortList(toc=["A01"]), k=2)
