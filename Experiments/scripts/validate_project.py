import os
import json
import shutil
import argparse

# define Error class
# 1. project_path does not exist
# 2. empty contracts


# 1. CompilerVersion
# 2. path convert
class NoProjectPathError(Exception):
    pass


class EmptyContractsError(Exception):
    pass


def move_out(file_path: str, dest_dir: str):
    # move the filepath to dest_dir
    if not os.path.exists(file_path):
        print(f"File {file_path} does not exist.")
        return

    try:
        rel_path = os.path.relpath(file_path, start="original")
        dst_file = os.path.join(dest_dir, rel_path)
        dest_dir = os.path.dirname(dst_file)
        # print(dest_dir)
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)

        shutil.copy(file_path, dst_file)
    except Exception as e:
        print(f"Error in moving file {file_path} to {dest_dir}.")
        print(e)
        return


def validate_project(source_dir):
    all_json_files = []
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".json"):
                all_json_files.append(os.path.join(root, file))

    print(f"Total projects: ", len(all_json_files))
    all_project = 0
    valid_project = 0
    for file_path in all_json_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                project_path = data["project_info"].get("project_path", None)
                if project_path:
                    all_project += 1
                    if type(project_path) is not dict:
                        proj = "../" + project_path
                        proj = proj.replace("\\", "/")
                        if not os.path.exists(proj):
                            raise NoProjectPathError(
                                f"Project path {project_path} does not exist.\n {file_path}"
                            )
                        else:
                            # check if the dir is empty
                            if not os.listdir(proj):
                                raise EmptyContractsError(
                                    f"Project path {project_path} is empty.\n {file_path}"
                                )
                        move_out(file_path, "valid")
                        valid_project += 1
                        continue
                    for key in project_path:
                        proj = project_path[key]
                        proj = "../" + proj
                        proj = proj.replace("\\", "/")
                        if not os.path.exists(proj):
                            raise NoProjectPathError(
                                f"Project path {proj} does not exist.\n {file_path}"
                            )
                        else:
                            # check if the dir is empty
                            if not os.listdir(proj):
                                raise EmptyContractsError(
                                    f"Project path {proj} is empty.\n {file_path}"
                                )
                    move_out(file_path, "valid")
                    valid_project += 1

        except NoProjectPathError as e:
            print(e)
            continue
        except EmptyContractsError as e:
            print(e)
            continue
    print(f"Total projects: ", all_project)
    print(f"Valid projects: ", valid_project)


if __name__ == "__main__":
    # move_out(
    #     "original/Techrate/$PePe coin Full Smart Contract Security Audit.json",
    #     "validate",
    # )
    parser = argparse.ArgumentParser(
        description="Count the total number of defects in all JSON files in a directory and its subdirectories."
    )

    parser.add_argument(
        "--source_dir",
        default="../Experiments/original",
        help="Source directory containing JSON files",
        required=False,
    )

    args = parser.parse_args()

    validate_project(args.source_dir)
