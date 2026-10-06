# GitTools v7.0

git命令行菜单工具。
Windows用GitTools.bat，Linux用GitTools.sh，Linux版部分功能没做完，请见谅，后续会发布修复版

文件：
GitTools.bat   Windows运行脚本
GitTools.sh    Linux脚本
git_tool.ini   配置
.gitignore     忽略配置
git_tool.log   运行日志，本地生成，不会上传

使用：
Windows系统，装好Git for Windows，直接双击GitTools.bat，输入数字选择功能。
Linux系统，安装git，再chmod +x GitTools.sh然后./GitTools.sh

功能：
提交，查看状态日志，分支操作，远程拉取推送，回退，stash，标签，处理冲突等。

注意：
github推送时密码填个人访问令牌，不是登录密码。
做删除、回退操作最好自己备份代码。
