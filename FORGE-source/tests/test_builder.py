import sys
import unittest
import os

from github import Github, Auth


sys.path.append(os.getcwd())
import builder
import dotenv

dotenv.load_dotenv()
from builder.utils import (
    StopIteration,
    read_json,
    write_json,
    log_to_file,
    get_log_status,
    path_handle,
)

TEST_URL = "https://github.com/abyssfinance/abyss-lockup/tree/8fe1a854a9b01dc1aa35272b82fd22655d4f42d1"


class TestGitFetcher(unittest.TestCase):
    def test_UrlParser(self):
        fetcher = builder.GitFetcher()

        assert fetcher.parse_url("https://github.com/TrailofBits/SCSTG") == None
        url = fetcher.parse_url(TEST_URL)
        assert url.proj == TEST_URL
        assert url.git_url == "https://github.com/abyssfinance/abyss-lockup"
        test_url2 = "https://github.com/dogechain-lab/dogechain"
        test_commit_id = "4dfcea48a3948d435f4d03c742fffe173f979739"
        url = fetcher.parse_url(test_url2, test_commit_id)
        assert url.branch == test_commit_id
        assert url.git_url == "https://github.com/dogechain-lab/dogechain"
        assert url.repo == "dogechain"
        return url

    def test_Auth(self):
        fetcher = builder.GitFetcher()
        g = fetcher.auth()
        assert fetcher.github_token is not None
        print(g.get_user().login)
        assert g.get_user().login is not None
        return g

    def test_Clone(self):
        # remove the f"./tests/{url.repo}"

        url = self.test_UrlParser()
        os.system(f"rm -rf ./tests/{url.repo}")
        self.test_Auth()
        fetcher = builder.GitFetcher()
        fetcher.clone_repo(url=url, output_path=f"./tests/{url.repo}")
        assert os.path.exists(f"./tests/{url.repo}")


class TestWalker(unittest.TestCase):
    def test_Walker(self):
        def action_test(file_path, base_name):
            # get file_path's filename
            # base_name = os.path.basename(file_path)

            if base_name == "202208101129":
                print(base_name)
                data = read_json(file_path)
                assert (
                    data["project_info"]["address"]
                    == "0x1B79549Bb3cAe5614f1A10D5E033F35C42d570BC"
                )
                raise StopIteration

        p = builder.JsonFileProcessor()
        p.walk_dir("../Experiments/original", action_test)

    def test_Log(self):
        os.system("rm -rf builder/logs/test.log")
        log_to_file("builder/logs/test.log", "info", "test")
        assert get_log_status("builder/logs/test.log")["info"] == ["test"]

    def test_PathHandle(self):

        result = path_handle(
            "../Experiments/original/Coinbae/Coinbae-Barnbridge_YieldFarmLP.json",
            "../Experiments/contracts/Coinbae-Barnbridge_YieldFarmLP",
        )
        print(result)
        assert result == "Experiments/contracts/Coinbae-Barnbridge_YieldFarmLP"

    def test_FetchChain(self):
        p = builder.JsonFileProcessor()
        res = p.fetch_from_chain(
            "0xde0b295669a9fd93d5f28d9ec85e40f4cb697bae", "./tests/202304171422"
        )
        chain = res[0]
        compiler_version = res[1]
        project_path = res[2]

        assert chain == "bsc"
        assert compiler_version == ["v0.8.10+commit.fc410830"]
        assert project_path == {"Farm": "./tests/202304171422/Farm"}
        assert os.path.exists("./tests/202304171422/Farm")

    def test_Fetch(self):
        p = builder.JsonFileProcessor(
            log_path="./tests/logs/test.json", dataset_path="./tests/contracts"
        )
        print("----Testing Fetch from Github----")
        p.fetch_action(
            "./tests/test_cases/git.json",
            base_name="git",
        )
        assert os.path.exists("./tests/contracts/git")
        print("ok.")
        print("----Testing Fetch from Chain----")
        p.fetch_action(
            "./tests/test_cases/address.json",
            base_name="chain",
        )
        assert os.path.exists("./tests/contracts/chain")
        print("ok.")
        print("----Testing Fetch from both----")
        p.fetch_action(
            "./tests/test_cases/both.json",
            base_name="both",
        )
        assert os.path.exists("./tests/contracts/both")
        print("ok.")
        print("----Testing Fetch from finished----")
        p.fetch_action(
            "./tests/test_cases/finished.json",
            base_name="finished",
        )
        assert os.path.exists("./tests/contracts/finished") == False
        print("ok.")


if __name__ == "__main__":

    unittest.main()
