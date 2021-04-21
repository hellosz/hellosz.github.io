#! /bin/bash
# 获取本机IP
# VAR=$(awk '{print $2}' ./.env)
# HOST_IP=$(ifconfig $VAR | grep "broadcast" | awk '{ print $2}')
# echo $HOST_IP

# build
bundle exec jekyll build

# 删除之前的启动脚本
sudo pkill bundle


# start jekyll serve
bundle exec jekyll serve --detach --port=9001


