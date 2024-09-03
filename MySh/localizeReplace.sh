#!/bin/bash
#文件夹下替换某一格式文件中多个字符串脚本
#替换的内容由一个文件输入，文件字符串以分隔符|分割作为替换内容
set -x
echo "欢迎使用帮助字符串快速替换文本脚本，此文本在英文单词量少时可能会有问题，其他特殊情况也会有，请小心使用，需要输入一个源文件，模版每行格式为："
echo "语言|被替换字串|替换字串"
echo "语言为文件夹名称字串"
# 检查文件是否存在
if [ ! -f "$1" ]; then
    echo " src.txt File does not exist."
    exit 1
fi

SPATH="/Users/gzsw/workspace/zyf/andy/localizeFileOutput/help"
TIMES=0
#cp -rf "$SPATH" "$DPATH"

file="$1";
shift
format="$1"

# 读取文件内容并替换
while IFS='|' read -r  before after;
do
    echo "Before replace: $before"
    echo "After replace: $after"

    ((TIMES++))
    #find . -name "*.${format}"
    echo "******查找开始并替换********"
    #查找并替换目录下的所有该格式文件
    find . -name "*.${format}" -exec sed -i '' "s#$before#$after#g" {} \;
    echo "******查找替换第${TIMES}次结束********"
    echo "replace compelete "
done < "${file}"
echo "------replace string success------"