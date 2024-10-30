# 732 CWEs
import pickle

cwe_dict = {}
with open("classify/cwe_dict.pkl", "rb") as f:
    cwe_dict = pickle.load(f)


from collections import deque


def bfs_traverse(root):
    count = set()
    if root is None:
        return

    queue = deque(root)
    level = 0

    while queue:
        level_size = len(queue)
        # print(f"Level {level}: ", end="")

        for _ in range(level_size):
            node = queue.popleft()
            count.add(node.ID)

            for child in node.Child:
                queue.append(child)

        # print()  # 换行,开始下一层
        level += 1
    print(len(count))
    # 假设root是CWE知识图谱的根节点


bfs_traverse(
    [
        cwe_dict["CWE-284"],
        cwe_dict["CWE-435"],
        cwe_dict["CWE-664"],
        cwe_dict["CWE-682"],
        cwe_dict["CWE-691"],
        cwe_dict["CWE-693"],
        cwe_dict["CWE-697"],
        cwe_dict["CWE-703"],
        cwe_dict["CWE-707"],
        cwe_dict["CWE-710"],
    ],
)
