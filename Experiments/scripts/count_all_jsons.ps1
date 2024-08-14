# 设置当前目录为工作目录
$directory = "../"

# 计算并输出json文件的数量
$jsonCount = (Get-ChildItem -Path $directory -Recurse -Filter *.json -File | Measure-Object).Count
Write-Output "There are $jsonCount JSON files in the directory and its subdirectories."
