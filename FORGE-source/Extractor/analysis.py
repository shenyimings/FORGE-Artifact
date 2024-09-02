import os
import json
import prompt
import logging
from datetime import datetime
from model import ChatOllama
from query import TocQuery, InfoQuery, FindingQuery
from document import PDFDocumentProcessor
from retriever import Retriever
from langchain_core.output_parsers import JsonOutputParser
from config import Config


def write_to_file(path: str, project: prompt.AnalysisOutput):
    with open(path, "w", encoding="utf8") as f:
        f.write(project.json())


def load_history(history_path: str):
    if os.path.exists(history_path):
        with open(history_path, "r") as f:
            return json.load(f)
    else:
        return {"Processed":{}}

def save_history(history: dict,history_path:str):
    with open(history_path, "w") as f:
        json.dump(history, f, indent=2)

def analyze_pdf(pdf_path: str, output_dir:str,config: Config):
    # max_retry_times = 3
    project_output = prompt.AnalysisOutput()
    project_output.path = pdf_path
    if pdf_path.endswith(".pdf"):
        ename = "pdf"
    elif pdf_path.endswith(".md"):
        ename = "md"
    else:
        logging.error("Unsupported file extension!")
        return
    logging.info(f"Creating {ename} Document Processor for {pdf_path}...")
    doc = PDFDocumentProcessor(pdf_path, config=config, extension_name=ename)
    logging.info("Creating Ollama models...")
    core_model = ChatOllama(
        "summary",
        temperature=config.summary_model_temperature,
        model_id=config.summary_model,
        base_url=config.base_url,
    ).create_model()
    # classify_model = ChatOllama(
    #     "classify",
    #     temperature=config.classify_model_temperature,
    #     model_id=config.classify_model,
    # ).create_model()
    logging.info("Creating Retriever...")
    retriever = Retriever(doc_processor=doc)
    toc_query = TocQuery(
        chat_model=core_model,
        retriever=retriever,
        output_parser=JsonOutputParser(),
    )

    finding_query = FindingQuery(
        chat_model=core_model,
        classify_model=core_model,
        retriever=retriever,
        output_parser=JsonOutputParser(),
    )
    info_query = InfoQuery(
        chat_model=core_model,
        retriever=retriever,
        output_parser=JsonOutputParser(),
    )
    logging.info("Getting TOC...")
    # DONE: Add retry here
    retry_times = config.max_retry_times
    while retry_times > 0:
        try:
            toc = toc_query.get_doc_toc(
                search_type=config.toc_search_type, k=config.toc_query_k
            )
            logging.info(toc)
            break
        except Exception as e:
            logging.error("Error: " + str(e))
            core_model.temperature += 0.1
            toc_query.chat_model = core_model
            retry_times -= 1
            continue
        
    core_model.temperature = config.summary_model_temperature
    logging.info("Analyzing document findings...")
    findings = finding_query.get_doc_findings(
        toc,
        search_type=config.toc_search_type,
        k=config.info_query_k,
        max_retry_times=config.max_retry_times,
    )
    project_output.findings = findings
    retry_times = config.max_retry_times
    while retry_times > 0:
        try:
            project_output.project_info = info_query.get_project_info(
                k=config.toc_query_k
            )
            break
        except Exception as e:
            logging.error("Error: " + str(e))
            core_model.temperature += 0.1
            info_query.chat_model = core_model
            retry_times -= 1
            continue
    doc._delete_collection()
    write_to_file(get_output_filename(pdf_path, output_dir), project_output)
    logging.info("Done.")

def get_output_filename(filepath: str, output_dir: str) -> str:
    timestamp = datetime.now().strftime("%H%M%S")
    base_name = os.path.basename(filepath)
    name, ext = os.path.splitext(base_name)
    new_filename = f"{output_dir}/{name}.json"
    if os.path.exists(new_filename):
        return f"{output_dir}/{name}_{timestamp}.json"
    return new_filename


def analyze_dir(dir_path: str, config: Config):
    history = load_history(config.history)
    for root, dirs, files in os.walk(dir_path):

        for file in files:
            rel_path = os.path.relpath(os.path.join(root, file), dir_path)
            parent_dir = os.path.dirname(rel_path)
            output_dir = os.path.join(config.output_dir, parent_dir)
            # print(parent_dir)
            os.makedirs(output_dir, exist_ok=True)
            parent_result = history["Processed"].get(parent_dir,[])
            # print(parent_result,file)
            # exit(0)
            if parent_result and str(file) in history["Processed"][parent_dir]:
                # logging.debug(str(file)+" processed.")
                continue
            if parent_dir == "":
                parent_dir = "0"
            try:
                analyze_pdf(os.path.join(root, file), output_dir,config)
                # print(parent_result)
                # print(str(file))
                parent_result.append(str(file))
                history["Processed"][parent_dir] = parent_result
                save_history(history,config.history)
            except Exception as e:
                logging.error(e)
                # analyze_pdf(os.path.join(root, file), output_dir,config)
                # exit(1)


# def analyze_pdf_test(pdf_path):
#     max_retry_times = 3
#     project_output = prompt.AnalysisOutput()
#     project_output.path = pdf_path
#     logging.info(f"Creating PDF Document Processor for {pdf_path}...")
#     doc = PDFDocumentProcessor(
#         pdf_path,
#         embedding_model="BAAI/bge-base-en-v1.5",
#         split_literal=[("#", "H1"), ("##", "H2"), ("###", "H3"), ("####", "H5")],
#     )
#     logging.info("Creating Ollama models...")
#     core_model = ChatOllama("core", temperature=0.1).create_model()
#     classify_model = ChatOllama("classify", temperature=0.1).create_model()
#     logging.info("Creating Retriever...")
#     retriever = Retriever(doc_processor=doc)
#     toc_query = TocQuery(
#         chat_model=core_model,
#         retriever=retriever,
#         output_parser=JsonOutputParser(),
#     )
#     fsl = toc_query.get_doc_toc()
#     print(fsl.toc)
#     retriever.search_kwargs.update({"k": 10})
#     print(retriever.invoke(str(fsl.toc)))


# logging.basicConfig(
#     level=logging.INFO,
#     format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
#     datefmt="%Y-%m-%d %H:%M:%S",
# )

# analyze_pdf_test(
#     "sample\Inspex_AUDIT2022031_BaryonNetwork_BaryonFarm_FullReport_v1.0.pdf"
# )
