import dotenv
import logging
from analysis import analyze_pdf, analyze_dir
from config import Config

"""
1. Input a pdf file
2. pdf2md，标题增强
3. 向量化后存入向量数据库
4. 查询toc，得到toc分段
5. 将toc分段送给llm，获得所有security findings的标题内容
6. 依次查询每个finding，得到finding内容
7. 令总结llm生成json摘要内容，格式化json输出
8. 令分类llm对该finding进行分类，格式化json输出
9. 合并全部JSON
10. 查询项目的repo url, commit hash, on-chain address等信息，生成JSON
11. 导出JSON文件
"""


if __name__ == "__main__":
    # print(torch.__version__)
    # os.system('nvidia-smi')
    config = Config(embedding_model="./bge-base-en-v1.5")
    dotenv.load_dotenv()
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    # analyze_pdf(
    #     "./Audit_Reports_2024/MixBytes/Abyss Eth2 Depositor.md",
    #     config,
    # )
    analyze_dir("./Audit_Reports_2024", config)



# ./sample/Inspex_AUDIT2022031_BaryonNetwork_BaryonFarm_FullReport_v1.0.pdf
