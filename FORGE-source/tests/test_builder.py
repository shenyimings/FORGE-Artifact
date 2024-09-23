import sys
import unittest
import os

from github import Github, Auth


sys.path.append(os.getcwd())
import builder

TEST_URL = "https://github.com/abyssfinance/abyss-lockup/tree/8fe1a854a9b01dc1aa35272b82fd22655d4f42d1"


class TestGitFetcher(unittest.TestCase):
    def test_UrlParser(self):
        fetcher = builder.GitFetcher()

        assert fetcher.parse_url("https://github.com/TrailofBits/SCSTG") == None
        url = fetcher.parse_url(TEST_URL)
        assert url.proj == TEST_URL
        assert url.git_url == "https://github.com/abyssfinance/abyss-lockup"
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
        keys = [
            "path",
            ["project_info", "url", "commit_hash"],
            ["project_info", "is_exists"],
        ]
        walker = builder.Walker()

        builder.fetch_code()


if __name__ == "__main__":
    unittest.main()
