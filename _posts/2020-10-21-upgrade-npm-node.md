---
title: Linux环境升级npm和node操作指南
tags: technical algorithm
category: technical
key: 
comment: true


---

这次在重新部署测试环境的项目的时候，遇到node.js版本的问题，让运维将node升级至线上版本的同时，自己将本地虚拟机的node和npm同步升级，保持版本一致避免问题出现。

于是将过程整理成笔记，方便以后参考。

<!--more-->

# 一、升级npm



## 1. 检查当前的npm版本

>  npm -v

![img](/assets/screenshots/update-npm-node/11.png)



## 2. 安装稳定版本（或者指定版本）的npm

> sudo npm install npm@stable -g

![img](/assets/screenshots/update-npm-node/12.png)

## 3. 查看是安装成功

> npm -v

![img](/assets/screenshots/update-npm-node/13.png)

# 二、升级node

（当前patpat的线上版本使用的是`v8.15.1`），可以使用**nvm**切换**node**版本，后面可以试一下

## 1. 查看当前node版本

> node -v

(当前为`v4.4.7`)

## 2. 强制清除缓存

> sudo npm cache clean --force

![img](/assets/screenshots/update-npm-node/21.png)

## 3. 使用npm安装node包管理工具n

> sudo npm install -g n

![img](/assets/screenshots/update-npm-node/22.png)

## 4. 使用n工具安装稳定的node

> // 安装稳定版本 
> sudo /usr/local/node/bin/n stable
>
> 
>
> // 安装指定版本 
>
> // sudo /usr/local/node/bin/n 8.15.1

![img](/assets/screenshots/update-npm-node/23.png)

安装结果显示**installed**，表示安装成功

## 5. 查看安装结果

> node -v

![img](/assets/screenshots/update-npm-node/24.png)

恭喜你，按照这个流程就成功的完成了npm还有node的**升级工作**啦



## 参考：

- [Interactively Manage Your Node.js Versions](https://www.npmjs.com/package/n)

