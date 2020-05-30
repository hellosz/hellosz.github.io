#! /bin/bash
# 获取本机IP
VAR=$(awk '{print $2}' ./.env)
HOST_IP=$(ifconfig $VAR | grep "broadcast" | awk '{ print $2}')
# echo $HOST_IP

# start jekyll serve
bundle exec jekyll serve --watch --trace --host=$HOST_IP --incremental


