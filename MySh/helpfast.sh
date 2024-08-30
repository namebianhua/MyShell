#!/bin/bash
#文件夹下替换某一格式文件中多个字符串脚本
#替换的内容由一个文件输入，文件字符串以分隔符|分割作为替换内容

echo "欢迎使用帮助字符串快速替换文本脚本，此文本在英文单词量少时可能会有问题，其他特殊情况也会有，请小心使用，需要输入一个源文件，模版每行格式为："
echo "语言|被替换字串|替换字串"
echo "语言为文件夹名称字串"
# 检查文件是否存在
if [ ! -f "$1" ]; then
    echo " src.txt File does not exist."
    exit 1
fi

SPATH="/Users/gzsw/workspace/zyf/andy/localizeFileOutput/help"
DPATH="/home/zyf/dev/sudoku-master/build/tmp"
DSRCPATH="/Users/gzsw/workspace/zyf/andy/WebHelp"

#cp -rf "$SPATH" "$DPATH"
#cd $SPATH/$lan.lproj/WebHelp/

# 读取文件内容
while IFS='|' read -r lan before after;
do
    echo "lan: $lan"
    echo "Before: $before"
    echo "After: $after"
    #检查文件夹是否存在
    if [ -d "$SPATH/$lan.lproj/WebHelp/"]; then 
        echo "folder exists"
    else
        echo "folder do not exists "
    fi
    cd $SPATH/$lan.lproj/WebHelp/
    pwd
    htms=`ls *.htm`
    #替换所有该文件后缀文件中的字串
    for htm in $htms
    do
	    sed -i '' "s#$before#$after#g" $htm
    done
    echo "$after complete"
    #cd -
    #cd $DPATH 
done < "$1"
cd  $SPATH
echo "------replace string success------"