import dotenv
from JsonFileProcessor import JsonFileProcessor


def main():
    p = JsonFileProcessor()
    p.walk_dir("../Experiments/original", p.fetch_action)


if __name__ == "__main__":
    dotenv.load_dotenv()
    main()
