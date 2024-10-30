import xml.etree.ElementTree as ET
from CWE import CWE
from CWE import EXCLUDE_CWE


def parse_cwe_xml(file_path):
    tree = ET.parse(file_path)
    # ET.register_namespace("", "http://cwe.mitre.org/cwe-7")  # 默认命名空间使用空字符串
    # ET.register_namespace("xhtml", "http://www.w3.org/1999/xhtml")
    # ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    root = tree.getroot()
    print(list(root))
    # root = root.get("Weakness_Catalog/Weaknesses")
    cwe_dict = {}  # 用于存储ID到CWE实例的映射
    # a = root.findall("{http://cwe.mitre.org/cwe-7}Weaknesses")
    for weakness in root.findall("Weaknesses/Weakness"):
        cwe_id = weakness.get("ID")
        if str("CWE-" + cwe_id) in EXCLUDE_CWE:
            continue
        name = weakness.get("Name")
        abstraction = weakness.get("Abstraction")
        description = weakness.find("Description")
        extended_description = weakness.find("Extended_Description")
        mapping_notes = weakness.find("Mapping_Notes/Usage").text
        if description is not None:
            description = description.text
            description = description.replace("\n\t\t\t\t\t", " ")
        elif extended_description is not None:
            description = extended_description.text
        else:
            description = ""

        cwe = CWE(
            ID=int(cwe_id),
            Name=name,
            Description=description,
            Abstraction=abstraction,
            Mapping=mapping_notes,
        )

        cwe_dict["CWE-" + cwe_id] = cwe
    print("Parsing relationships...")
    for weakness in root.findall("Weaknesses/Weakness"):
        for related in weakness.findall("Related_Weaknesses/Related_Weakness"):
            if related.get("Nature") == "ChildOf" and related.get("View_ID") == "1000":
                child_id = weakness.get("ID")
                parent_id = related.get("CWE_ID")
                if (
                    str("CWE-" + parent_id) in EXCLUDE_CWE
                    or str("CWE-" + child_id) in EXCLUDE_CWE
                ):
                    continue
                cwe_dict["CWE-" + parent_id].add_child(cwe_dict["CWE-" + child_id])
            if related.get("Nature") == "PeerOf" and related.get("View_ID") == "1000":

                peer_id = related.get("CWE_ID")
                if (
                    str("CWE-" + peer_id) in EXCLUDE_CWE
                    or str("CWE-" + weakness.get("ID")) in EXCLUDE_CWE
                ):
                    continue
                cwe_dict["CWE-" + weakness.get("ID")].Peer.append(
                    cwe_dict["CWE-" + peer_id]
                )

    return cwe_dict


cwe_dict = parse_cwe_xml("FORGE-source/mapper/1000.xml")

import pickle

with open("FORGE-source/mapper/cwe_dict.pkl", "wb") as f:
    pickle.dump(cwe_dict, f)


import json

# for id, cwe in cwe_dict.items():
#     print(id, cwe)
#     cwe_dict[id] = cwe.model_dump_json(indent=2)


def model_dump_json(
    obj,
):
    return {
        "ID": obj.ID,
        "Name": obj.Name,
        "Description": obj.Description,
        "Abstraction": obj.Abstraction,
        "Peer": [peer.ID for peer in obj.Peer],
        "Parent": [parent.ID for parent in obj.Parent],
        "Child": [child.ID for child in obj.Child],
        "Mapping": obj.Mapping,
    }


with open("cwe_dict2.json", "w") as f:

    json.dump(cwe_dict, f, default=model_dump_json, sort_keys=False, indent=2)
