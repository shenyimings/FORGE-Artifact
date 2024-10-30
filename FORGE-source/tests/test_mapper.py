import sys
import unittest
import dotenv
from langchain.prompts import ChatPromptTemplate

sys.path.append("/root/FORGE-Artifact/FORGE-source")
from mapper.CloudflareLLM import CloudflareLLM
from mapper.CWE import CWE, CWEHandler

# from mapper.config import


class TestCloudflareLLM(unittest.TestCase):
    def __init__(self, methodName: str = "runTest") -> None:
        self.cf_id = dotenv.get_key(".env", "CF_ID")
        self.cf_token = dotenv.get_key(".env", "CF_TOKEN")
        super().__init__(methodName)

    def test_init(self):
        cf_id = self.cf_id
        cf_token = self.cf_token
        llm = CloudflareLLM(
            model="@cf/meta/llama-3.1-70b-instruct",
            account_id=cf_id,
            api_token=cf_token,
        )
        self.assertEqual(llm.model, "@cf/meta/llama-3.1-70b-instruct")
        self.assertIsNotNone(llm.api_token)
        self.assertIsNotNone(llm.account_id)

    # def test_call(self):
    #     # dotenv.load_dotenv(".env")
    #     cf_id = self.cf_id
    #     cf_token = self.cf_token
    #     llm = CloudflareLLM(account_id=cf_id, api_token=cf_token)
    #     res = llm._call("Hi, test test")
    #     self.assertIsInstance(res, str)
    #     print(res)

    # def test_runnable(self):
    #     cf_id = self.cf_id
    #     cf_token = self.cf_token
    #     llm = CloudflareLLM(
    #         account_id=cf_id,
    #         api_token=cf_token,
    #         temperature=0.2,
    #     )
    #     prompt = ChatPromptTemplate.from_messages([("user", "Hi, test test")])
    #     callables = prompt | llm
    #     result = callables.invoke({})
    #     print(result)
    #     self.assertIsInstance(result, str)
    def test_parse(self):
        test_str = """
To perform Root Cause Analysis on the given vulnerability title and description, let's break it down step by step:

1. **Vulnerability Title**: Local Variables Shadowing
2. **Vulnerability Description**: The _approve function's owner variable shadows Ownable's owner function.

From the title and description, we understand that there is an issue with variable shadowing. Variable shadowing occurs when a variable declared within a certain scope (decision block, method, or inner class) has the same name as a variable declared in an outer scope. This can lead to confusion about which variable is being accessed or modified.

Given the description, the issue arises from the _approve function's owner variable having the same name as Ownable's owner function. This is a classic case of shadowing, where two variables with the same name are used in different scopes, potentially leading to confusion or incorrect behavior.

Let's examine the provided CWE IDs:

- **CWE-284: Improper Access Control**: This doesn't directly relate to shadowing; it's more about access restriction failures.
- **CWE-435: Improper Interaction Between Multiple Correctly-Behaving Entities**: While it talks about interactions leading to weaknesses, it's more about system-level interactions than variable shadowing.
- **CWE-664, CWE-682, CWE-691, CWE-693, CWE-697, CWE-703, CWE-707, CWE-710**: None of these directly address the issue of variable shadowing either.

However, none of the provided CWE IDs directly address variable shadowing. But, considering the nature of variable shadowing leading to potential confusion or incorrect behavior due to hidden or obscured variables, the closest match in spirit from the given options might seem to be **CWE-691: Insufficient Control Flow Management**, as it talks about not sufficiently managing control flow, which could be argued to include the confusion caused by shadowing. However, this is a stretch since CWE-691 is more about the flow of program execution rather than naming conflicts.

Given the provided options, none perfectly match. In a broader context, a more fitting CWE might be **CWE-561: Dead Code**, **CWE-563: Assignment to Variable Without Use**, or even **CWE-604: Internal Settle Matters Public Exposure through Vulnerability**, which relate to various forms of code misuse or confusion, but these were not provided.

Given the available options, I select **CWE-691** as the closest fit, acknowledging that it's not"""
        cwe_handler = CWEHandler()
        cwe_handler.load_dict("FORGE-source/mapper/cwe_dict_20241024.json")
        cwe_id_list = cwe_handler.cwe_from_string(test_str)
        print(cwe_id_list)
        cwe = cwe_handler.parse_cwe_list(cwe_id_list)
        self.assertIsInstance(cwe, list)
        # print(cwe)
        assert cwe[0]["ID"] == 691


if __name__ == "__main__":
    # 只测试init
    unittest.main()
