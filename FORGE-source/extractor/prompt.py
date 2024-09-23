from langchain_core.prompts import ChatPromptTemplate
from langchain_core.pydantic_v1 import BaseModel, Field, conlist, constr
from langchain_core.prompts.few_shot import FewShotPromptTemplate
from langchain_core.prompts.prompt import PromptTemplate
from typing import Any, List, Union
import re


class ProjectInfo(BaseModel):
    url: str = Field(
        description="The project source code URL",
        default="N/A",
        example="https://github.com/aloelabs/aloe-blend",
    )
    commit_hash: str = Field(
        description="The commit hash of audited code",
        default="N/A",
        example="78aac842b728f71fd3912bec9f536ac8c1e8015d",
    )
    address: Any = Field(
        description="The on-chain address of the audited contract",
        default="N/A",
        example="0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae",
    )

    @classmethod
    def generate_example(cls) -> str:
        return ProjectInfo(
            url="https://github.com/aloelabs/aloe-blend",
            commit_hash="78aac842b728f71fd3912bec9f536ac8c1e8015d",
            address="0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae",
        ).json()


CWE_ID = constr(regex=re.compile(r"^CWE-\d+$", re.IGNORECASE), to_upper=True)


class Category(BaseModel):
    category: conlist(CWE_ID, min_items=0)

    @classmethod
    def generate_example(cls) -> str:
        return Category(category=["CWE-284", "CWE-435"]).json()


# a = Category(category=["CWE-284"])
# print(Category.generate_example())


class Finding(BaseModel):
    id: int = Field(
        description="The unique ID of the security finding", default=0, example=0
    )
    category: Union[list, str] = Field(
        description="The CWE ID(s) for the security finding",
        default=[],
        example=["CWE-284"],
    )
    title: str = Field(
        description="The title of the security finding",
        default="N/A",
        example="Precision Loss in Division and Multiplication Finding",
    )
    description: str = Field(
        description="A short description of the security finding",
        default="N/A",
        example="In the withdraw function of DeltaNeutralVault, multiplying after division without proper method can cause precision loss, leading to failure of _withdrawHealthCheck.",
    )
    severity: str = Field(
        description="The severity of the security finding",
        default="N/A",
        example="Critical",
    )
    contract: Union[str, list, None] = Field(
        description="The name of the contract where exists the security finding",
        default="N/A",
        example="DeltaNeutralVault",
    )
    function: Union[str, list, None] = Field(
        description="The name of the function where exists the security finding",
        default="N/A",
        example="withdraw()",
    )
    lineNumber: Union[list, str, int, None] = Field(
        description="The line numbers where exist the security finding",
        default="N/A",
        example="317-319",
    )
    # check_ouput，判断Finding里,title/description ...有几项是'N/A'

    @classmethod
    def check_output(cls, output: dict, threshold: int = 3):
        na_num = sum([1 for k, v in output if v == "N/A"])
        print(na_num)
        if na_num >= threshold:
            return False
        return True

    @classmethod
    def generate_example(cls) -> str:
        # a = {}
        # a.keys
        # cls.schema()["properties"].keys()
        # example = [
        #     "A01.Minting of unlimited number of sundae tokens?",
        #     "A02.Potential unauthorized script upgrade",
        # ]
        return Finding(
            id=0,
            category=["CWE-284"],
            title="Precision Loss in Division and Multiplication Finding",
            description="In the withdraw function of DeltaNeutralVault, multiplying after division without proper method can cause precision loss, leading to failure of _withdrawHealthCheck.",
            severity="Critical",
            contract="DeltaNeutralVault",
            function="withdraw()",
            lineNumber="317-319,320",
        ).json(exclude={"id", "category"})


# print(Finding.generate_example())


class FindingShortList(BaseModel):
    toc: Any = Field(
        description="The title of all the findings.",
        default=[],
    )

    @classmethod
    def generate_example(cls) -> str:

        example = [
            "Minting of unlimited number of sundae tokens",
            "Potential unauthorized script upgrade",
        ]
        return FindingShortList(toc=example).json()


# fsl = FindingShortList(toc=["123", "123"])
# print(fsl.generate_example())


class AnalysisOutput(BaseModel):
    path: str = Field(description="The path to the file", default="N/A")
    project_info: ProjectInfo = Field(
        description="The project information", default=ProjectInfo()
    )
    findings: List[Finding] = Field(
        description="The list of security findings", default=Finding()
    )


# a = AnalysisOutput(path="1", project_info=ProjectInfo(), findings=Finding())
# print(a.json())
# Get the Table of Findings content
get_toc_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "user",
            """
Using text snippets extracted from the "Table of Findings" and "Audit Overview" section of smart contract security audit reports, identify existing security findings or vulnerabilities detected by the auditor. 
Format the output as a JSON object following the structure like: ```{output_format}```.

Input:
Here are the snippets from the "Table of Findings" and "Audit Overview" section: {relevant_docs}.

Task:
Extract the names or titles of existing security findings or vulnerabilities the audited code has from the provided snippets. Ensure the extracted data is structured according to the JSON format above.

Output:
Only provide a JSON-formatted list of extracted security findings or vulnerabilities, adhering to the specified format.
""",
        ),
    ]
)


# Get each finding of the audit report
jsonify_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are a professional assistant focusing on summarizing vulnerabilities in smart contract audit reports, and designed to output JSON.",
        ),
        (
            "user",
            """As an assistant specializing in smart contract security, you are tasked with analyzing provided audit report fragments. Based on the finding title '{query}', summarize and extract specific details about this finding. Your response should be formatted as a JSON object, conforming to the structure specified in ```{output_format}```.
Input:
Here are the audit report fragments: {relevant_docs}.

Task:
For each security finding in the audit report:

Summarize the finding '{query}'s title, a description, and its severity level. Extract the code location where the vulnerability exists, including contract name, function and line number. If specific information is not mentioned in the fragments, use "N/A" for that item. Output should be strictly in JSON, anything else should not be included in the output.
            """,
        ),
    ]
)


get_category_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "user",
            """
As a professional vulnerability classification assistant, your task is to map the given vulnerabilities into CWE (Common Weakness Enumeration) types based on their titles and descriptions. You are to format your output in Markdonw JSON according to the structure specified in ```json\n{output_format}```.

Input Finding Info:
Title of the security finding: {title}.
Description of the security finding: {description}.

CWE Knowledge:
CWE category information: {knowledge}.

Output:
Only provided a json-formatted list of CWE ID for the security finding based on the information provided, anything else should not be included in the output.

Task:
Analyze the title and description of the security finding and classify it into the appropriate CWE category based on the provided CWE category information. Your output should be strictly formatted as a JSON object, explanation and anything else should not be included in the output, now: ```json

            """,
        )
    ]
)

get_info_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "user",
            """
As a specialized assistant in analyzing smart contract audit reports, your task is to extract key information about the audited project from the provided relevant documents. Specifically, you need to identify the repository URL of the project source code, the commit hash of the source code under review, and the on-chain address of the project.

Input:
Audit report documents: {relevant_docs}.

Task:
From the audit report, extract the following information:

The URL of the project's source code repository, typically a GitHub URL like "https://github.com/..."
The commit hash of the source code that was reviewed in the audit.
The on-chain address of the project, if available.

Output Format:
Format the extracted information into a JSON object following the structure specified in '{output_format}', anything else should not be included in the output. If any information is not available in the provided documents, include "N/A" for that item. No comments or additional text should be included in the output.
""",
        )
    ]
)


finding_format = """```json
{"title": "Precision Loss in Division and Multiplication Finding","severity": "Critical","contract": "N/A","function": "N/A","lineNumber": "317"
                  "description": "In the withdraw function of DeltaNeutralVault, multiplying after division without proper method can cause precision loss, leading to failure of _withdrawHealthCheck."
                  }
                  ```"""

core_output_example = """
```json
{
queries:["What is A01.Minting of unlimited number of sundae tokens?",...]
}
```
"""


query_output = """
```json
{
    "query_name": ans_1,
    "query_name": ans_2,
    ...
    "query_name": ans_n,
}
```
"""
# Get project source code URL, the commit hash of audited code and the on-chain address
query_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "user",
            "As a helpful assistant in smart contract security audit reports analysis, you need to answer the queries based on the text snippets containing relevant information. When a specific information item is not directly mentioned in the snippets, you must input 'N/A' for that item. Your output should be formatted in JSON like {query_output}.\n Here is the name and value of the queries: {query}.\n Here is the text snippets: {query_doc}. Now: \n```json\n",
        ),
    ]
)

# Classify the CWE Pillar ID(s) for the security finding


classify_output = """
```json
{
    result:[
            {
                "id": 0,
                "category": ["CWE-284", "CWE-682"]
            },
            {
            ...
            }
        ]
}
```
"""


system = "You are a professional assistant focusing on summarizing vulnerabilities in smart contract audit reports, and designed to output JSON."

user = """As an AI model, your task is to analyze the provided audit report. Your output should be formatted in JSON! For each finding in the report, summarize the title, description and severity level, extract the contract name, function, and line number, assign CWE Pillar(CWE-284/435/664/682/691/693/697/703/707/710) ID(s) for it. Additionally, identify the project source code URL, the commit hash of audited code and the on-chain address. In instances where specific information is unavailable, please input 'N/A' for that item. Structure your JSON output as illustrated in the example below:{output_format}
Here is the
"""
output_format = """
{
    "project": "https://github.com/aloelabs/aloe-blend",
    "commit_hash": "78aac842b728f71fd3912bec9f536ac8c1e8015d",
    "address": "0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae",
    "findings": [
        {
            "ID": <UNIQUE_ID>(1,2,...),
            "title": "Precision Loss in Division and Multiplication Finding",
            "description": "In the withdraw function of DeltaNeutralVault, multiplying after division without proper method can cause precision loss, leading to failure of _withdrawHealthCheck.",
            "severity": "Low/Medium/High/Critical",
            "category": ["CWE-284","CWE-682"],
            "contract": "DeltaNeutralVault",
            "function": "withdraw()",
            "lineNumber": "317-319"
        },
        ...
    ]
}
"""

# test_query = {"queries": ['What is A01. Minting of unlimited number of sundae tokens?', 'What is A02. Accumulation of rounding errors when exchanging old liquidity tokens for new liquidity tokens?', 'What is A03. Any tokens with the currency symbol as the hash of poolMintingPolicyContract can be minted?', 'What is A04. Old script hashes shall never be reused when upgrading factory or treasury?', 'What is A05. More scooper fees could be collected with multiple scoopers public key hashes?', 'What is A06. Scooper could redeem more than the maximum number of scooper rewards?', 'What is A07. Potential unauthorized script upgrade?', 'What is A08. Assets in escrow contract can be stolen when upgrading pool?', 'What is A09. Scooper fees cannot be redeemed into treasury?', 'What is A10. Integer division is used multiple times in computation of token amount?',
#                           'What is A11. Rounding error is exacerbated in DepositSingle operation in pool contract?', 'What is A12. Assets in escrow contract can be stolen when redeeming liquidity tokens?', 'What is B01. Use of If-then-else for the or operator in poolMintingPolicyContract?', 'What is B02. Unconstrained usage of scooper token makes tracing of scoopers hard?', 'What is B03. Redundant checks in factory contract?', 'What is P01. Avoid higher-order functions and extra list traversals?', 'What is P02. Optimize atLeastOne uses, script address checks, flattenValue in Pool script?', 'What is P03. Avoid redundant computation in doEscrows?', 'What is P04. Rewrite rawDatumOf function?', 'What is E01. Less escrow riders are returned when multiple escrows from the same trader are scooped in a transaction?']}
test_query = {
    "queries": [
        "What is A03. Any tokens with the currency symbol as the hash of poolMintingPolicyContract can be minted?"
    ]
}
