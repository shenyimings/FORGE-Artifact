from graphviz import Digraph
import pickle
import json
import os

# 从cwe_dick.pkl 导入cwe_dict


def load_vulns(dirname: str):
    # walk the spec dir and read all json files

    cwe_distribution = {}
    for root, dirs, files in os.walk(dirname):
        for file in files:
            if file.endswith(".json"):
                with open(os.path.join(root, file)) as f:
                    data = json.load(f)
                    for finding in data["findings"]:
                        if finding["category"] == []:
                            continue
                        cwes = finding.get("category", {})
                        max_level = 0
                        for level in cwes.keys():
                            max_level = max(int(level), max_level)
                        max_level = str(max_level)
                        cwes[max_level][0] = cwes[max_level][0].upper()
                        cwe_distribution[cwes[max_level][0]] = (
                            cwe_distribution.get(cwes[max_level][0], 0) + 1
                        )
                        # for level in cwes.keys():
                        #     cwe_distribution[cwes[level][0]] = (
                        #         cwe_distribution.get(cwes[level][0], 0) + 1
                        #     )
    return cwe_distribution
    # print(cwe_distribution["CWE-284"])

    # all_json_files.append(os.path.join(root, file))


def calculate_bgcolor(occurrence_count, min_count=0, max_count=2000):
    # 确保 occurrence_count 在 min_count 和 max_count 之间
    occurrence_count = max(min_count, min(max_count, occurrence_count))

    # 计算红色分量的比例
    ratio = (occurrence_count - min_count) / (max_count - min_count)

    # 计算颜色值
    red = 255
    green = int(185 + (255 - 185) * (1 - ratio))
    blue = int(185 + (255 - 185) * (1 - ratio))

    return f"#{red:02X}{green:02X}{blue:02X}"


def visualize_tree(cwe_dict, root_id, cwe_distribution):
    dot = Digraph()
    max_name_length = 50
    abstraction_colors = {
        "Pillar": "#585858",
        "Class": "#12b14f",
        "Base": "#962b15",
        "Variant": "#702ba1",
        "Compound": "black",
    }

    def dfs(cwe_id: str, parent_id: str = None, current_level=0):
        cwe = cwe_dict[cwe_id]
        truncated_name = (
            cwe.Name[:max_name_length] + ".."
            if len(cwe.Name) > max_name_length
            else cwe.Name
        )
        occurrence_count = cwe_distribution.get(cwe_id, 0)
        # if occurrence_count == 0:
        #     return
        # bgcolor = "#FFCCCC" if occurrence_count > 200 else "white"
        bgcolor = calculate_bgcolor(occurrence_count)
        dot.node(
            cwe_id,
            label=f"{truncated_name}\n{cwe_id}\n{cwe.Abstraction}\n{occurrence_count}",
            fontcolor=abstraction_colors[cwe.Abstraction],
            style="filled",
            fillcolor=bgcolor,
        )
        if parent_id:
            dot.edge(parent_id, cwe_id)
        for child in cwe.Child:
            dfs("CWE-" + str(child.ID), cwe_id, current_level + 1)

    for pilliar in root_id:
        dfs(pilliar)
    # dfs(root_id)
    # dfs("CWE-435")

    return dot


CWE_PILLARS = [
    "CWE-284",
    "CWE-435",
    "CWE-664",
    "CWE-682",
    "CWE-691",
    "CWE-693",
    "CWE-697",
    "CWE-703",
    "CWE-707",
    "CWE-710",
]


def draw_separate():

    cwe_distribution = load_vulns("Experiments/valid")
    f = open("FORGE-source/mapper/cwe_dict_20241024.pkl", "rb")
    cwe_dict = pickle.load(f)
    f.close()

    for cwe_pillar in CWE_PILLARS:
        tree_graph = visualize_tree(cwe_dict, [cwe_pillar], cwe_distribution)
        tree_graph.graph_attr["rankdir"] = "LR"
        tree_graph.render(f"{cwe_pillar}", view=False)


def draw_all():
    cwe_distribution = load_vulns("Experiments/valid")
    f = open("FORGE-source/mapper/cwe_dict_20241024.pkl", "rb")
    cwe_dict = pickle.load(f)
    f.close()
    tree_graph = visualize_tree(cwe_dict, CWE_PILLARS, cwe_distribution)
    tree_graph.graph_attr["rankdir"] = "LR"
    tree_graph.render("cwe_tree_hier", view=False)


draw_all()
# tree_graph = visualize_tree(cwe_dict, "CWE-284", cwe_distribution)
# # tree_graph = visualize_tree(cwe_dict, "CWE-435", cwe_distribution)
# tree_graph.graph_attr["rankdir"] = "LR"
# # save to pdf file

# tree_graph.render("cwe_tree_284", view=False)
