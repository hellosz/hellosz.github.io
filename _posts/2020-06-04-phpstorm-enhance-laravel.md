# 准备
首先，请参考[设置PHPStorm快捷键][1]学习如何设置快捷键，再进行以下设置
# 1.设置快捷键
### 全局专注代码编辑
1. 代码专注（隐藏窗口）
> 将`Enter Distraction Free Mode`的快捷键设置成`alt + f11`
2. 全屏专注（隐藏菜单项）
> 将`Enter Full Screen`快捷方式设置成`f11`（通用全屏跨界方式）

### 最近编辑
1. 最近编辑文件
> `ctrl + e`

2. 最近编辑代码片段（简易/快速）
> `ctrl + shift + e`显示最近编辑代码片段，`ctrl + shift + backspace`快速回退光标到上次编辑

3. 常用功能（命令行、版本控制、Run Command）
> 命令行默认快捷方式是`alt + f12`，现修改为`alt + x`，版本控制默认快捷方式是`alt + 9`，现修改为`alt + z`


# 2.Laravel提示相关配置
### Laravel Plugin插件
> 在Settings->Plugins中，搜索Laravel安装，重启后即可使用

### Command Line快捷方式
> 原来默认的快捷方式是`ctrl+shift+x`

### Command Line支持artisan命令
1. 新建
> 在`Settings->Conmmand Line > Support`中，在弹出窗口的右上角点击`+`号，新建一个，`Visibility`选择`project`，点击`OK`

2. 设置
> 然后将 `Path to PHP executable`设置成`当前系统安装的php执行程序`,`Path to composer.phar or composer`设置成`（当前项目路径）/artisan`即可，点击`OK`
此时，使用`ctrl+shift+x`打开command窗口，输入artisan相关命令就会自动提示

### Laravel Blade模板提示快捷键
参考[Laravel Blade快捷键设置][2]

### Laravel IDE Helper自动提示
1. 使用`Composer`安装插件
> composer require --dev barryvdh/laravel-ide-helper
2. 在`config`目录的`app.php`中的`providers`的最后添加以下内容:
> Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider::class,
3. 在`app/Providers/AppServiceProvider.php`文件的`register()`方法中添加以下内容进行注册
```php
if ($this->app->environment() !== 'production') {
            $this->app->register(\Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider::class);
    }
```
4. 生成代码跟踪支持
> php artisan ide-helper:generate

---
## 参考
[1]: https://www.bilibili.com/video/BV1vJ41157eo?p=9 "后盾网向军大叔教你配置PHPStorm快捷键"
[2]: https://blog.csdn.net/bz0446/article/details/97113720 "PHPStorm中Blade模板快捷键定义"


[PHPStorm强大的开发工具](https://www.bilibili.com/video/BV1vJ41157eo?p=9)

[PHPStorm配置，提高Laravel开发效率](https://blog.csdn.net/weixin_41767780/article/details/80867138)

[PHPStorm中Blade模板快捷键定义](https://blog.csdn.net/bz0446/article/details/97113720)
