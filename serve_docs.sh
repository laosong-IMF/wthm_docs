#!/bin/bash

# 确保在项目根目录执行
cd "$(dirname "$0")"

# 激活虚拟环境 (如果需要)
# source .venv/bin/activate

# 复制共享资产
echo "复制共享资产到语言目录..."
cp -r docs/assets docs/zh/
cp -r docs/assets docs/en/

# 运行 MkDocs 服务
echo "启动英文文档服务..."
/home/laosong/work/gemini_cli/wthm_doc/.venv/bin/mkdocs serve -f mkdocs_en.yml &
EN_PID=$!
echo "英文文档服务PID: $EN_PID"

echo "启动中文文档服务..."
/home/laosong/work/gemini_cli/wthm_doc/.venv/bin/mkdocs serve -f mkdocs_zh.yml &
ZH_PID=$!
echo "中文文档服务PID: $ZH_PID"

echo "请访问 http://127.0.0.1:8000/ (英文) 和 http://127.0.0.1:8000/zh/ (中文) 预览文档。"
echo "按 Ctrl+C 停止服务并清理。"

# 等待用户中断
trap "kill $EN_PID $ZH_PID 2>/dev/null; rm -rf docs/zh/assets docs/en/assets; echo '服务已停止，清理完成。'" EXIT
wait $EN_PID $ZH_PID
