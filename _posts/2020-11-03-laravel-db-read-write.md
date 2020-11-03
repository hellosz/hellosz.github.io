---
title: Larave读写分离应用与原理解析
tags: technical laravel  database
category: technical
key: bf0cbbfefa8343b4cdfc45c92b368406
comment: true


---

原来公司当前的项目的MySQL一直有配置**主动数据库**，但是线上环境的项目只使用了**写库**，所以趁着这次配置主从的机会，花了点时间看了下Laravel的源码，梳理清楚了Laravel是如何创建不同类型的数据库连接，并如何强制使用写连接的。

在这里总结出来，希望能帮到一些朋友。

<!--more-->
---
### 配置
修改`config/database.php`文件中的`database.php`文件，如下所示（一读一写）：
```php
'connections' => [
        'mysql' => [
            // 读库，读取.env环境配置
            'read' => [
                'host'      => env('DB_READ_HOST', 'localhost'),
                'username'  => env('DB_READ_USERNAME', 'forge'),
                'password'  => env('DB_READ_PASSWORD', ''),
            ],
            // 写库，读取.env环境配置
            'write' => [
                'host'      => env('DB_WRITE_HOST', 'localhost'),
                'username'  => env('DB_WRITE_USERNAME', 'forge'),
                'password'  => env('DB_WRITE_PASSWORD', ''),
            ],
            'driver'    => 'mysql',
            'port'      => env('DB_PORT', '3306'),
            'database'  => env('DB_DATABASE', 'forge'),
            'charset'   => 'utf8',
            'collation' => 'utf8_unicode_ci',
            'prefix'    => '',
            'strict'    => false,
            'engine'    => null,
        ]
    ];
```
`read`和`write`都可以设置为二维数组，表示多个读库和写库

---
### 应用
#### 1、常用的查询类型 
- Raw Queries 原始查询
> DB::select('select * from users');

- Query Builder 查询生成器
> \Illuminate\Database\Query\Builder::$connection
> 
> DB::table('users')->get();

- Eloquent 持久化
> \Illuminate\Database\Eloquent\Builder::$query
> 
> User::where('id', 1)->get();

#### 2、强制使用写连接
针对`Raw Queries原始查询`，可以使用`select()`方法，将第三个参数设置为**false**：
> DB::select('select * from users', [], false);  // false表示使用不使用readPdo

更简便的方式使用使用封装的`selectFromWriteConnection()`方法：
> DB::selectFromWriteConnection('select * from users');

针对`Query Builder查询生成器`、`Eloquent持久化`的方式，可使用`useWritePdo()`方法：
> DB::table('users')->useWritePdo()->get();
>
> User::useWritePdo()->get();

---

### 原理解析
无论是三种查询中的哪种查询，本质上都是调用`\Illuminate\Database\Connection::select($query, $bindings = [], $useReadPdo = true)`方法，将`$useReadPdo`设置为`false`实现**强制使用**写连接的结果。

接下来，我们来看一下Laravel底层是如何初始化读写连接、上述的两种方式（`useWritePdo()`、`selectFromWriteConnection`）调用`Connection::select()`方法的。

**备注：以下的代码使用的Laravel 5.2版本**

#### 1、创建读写连接
##### 1.1、创建连接
`\Illuminate\Database\Connectors\ConnectionFactory`类，负责根据配置创建PDO连接。

```php
/**
     * Establish a PDO connection based on the configuration.
     *
     * @param  array   $config
     * @param  string  $name
     * @return \Illuminate\Database\Connection
     */
    public function make(array $config, $name = null)
    {
        $config = $this->parseConfig($config, $name);

        if (isset($config['read'])) {
            return $this->createReadWriteConnection($config);
        }

        return $this->createSingleConnection($config);
    }
```
其中，如果当前的`database.php`中的数据源链接配置了`['connection']['connection_name']['write']`项，则会调用`createReadWriteConnection()`方法，创建[随机创建读写连接](#12随机创建读写连接)，否则只会创建单链接

##### 1.2、随机创建读写连接
现在，我们来看一下Laravel是如何随机创建**读写连接**的。

在`createReadWriteConnection()`方法中创建连接对象，分别将**写连接**保存在`$connection->pdo`中，**读连接**保存在`$connection->readPdo`中
```php
    /**
     * Create a single database connection instance.
     *
     * @param  array  $config
     * @return \Illuminate\Database\Connection
     */
    protected function createReadWriteConnection(array $config)
    {
        // 设置写连接
        $connection = $this->createSingleConnection($this->getWriteConfig($config));

        // 设置读连接
        return $connection->setReadPdo($this->createReadPdo($config));
    }
```


创建连接的的时候，如果`$type='write'`，会通过调用`$this->getWriteConfig($config)`调用`getReadWriteConfig(array $config, 'write')`方法，如果配置了多个连接，会随机从中获取一个，否则取默认配置，这里就实现了随机创建连接
```php
    /**
     * Get a read / write level configuration.
     *
     * @param  array   $config
     * @param  string  $type
     * @return array
     */
    protected function getReadWriteConfig(array $config, $type)
    {
        if (isset($config[$type][0])) {
            // 如果配置了多个连接，则随机获取获取其中一个
            return $config[$type][array_rand($config[$type])];
        }

        // 获取默认配置
        return $config[$type];
    }
```

#### 2、手动设置写连接如何生效？
##### 2.1、使用useWritePdo()
将`$this->useWritePdo`属性是指为`true`，表示使用**写连接**
```php
    /**
     * Use the write pdo for query.
     *
     * @return $this
     */
    public function useWritePdo()
    {
        // useWritePdo初始化为false
        $this->useWritePdo = true;

        return $this;
    }
    
```

在设置好查询条件，最后使用`\Illuminate\Database\Query\Builder`的`get()`方法获取数据时，就会调用自身的`runSelect()`，其中会将`$this->useWritePdo`**取反**作为`\Illuminate\Database\Connection::select()`第三个参数值，即`$useReadPdo = false`

```php
    /**
     * Execute the query as a "select" statement.
     *
     * @param  array  $columns
     * @return array|static[]
     */
    public function get($columns = ['*'])
    {
        $original = $this->columns;

        if (is_null($original)) {
            $this->columns = $columns;
        }

        $results = $this->processor->processSelect($this, $this->runSelect());

        $this->columns = $original;

        return $results;
    }

    /**
     * Run the query as a "select" statement against the connection.
     *
     * @return array
     */
    protected function runSelect()
    {
        return $this->connection->select($this->toSql(), $this->getBindings(), ! $this->useWritePdo);
    
```

##### 2.2、使用selectFromWriteConnection()
这里会更加直接，直接调用`select()`方法，将`$useReadPdo`设置为`false`
```php
    /**
     * Run a select statement against the database.
     *
     * @param  string  $query
     * @param  array   $bindings
     * @return array
     */
    public function selectFromWriteConnection($query, $bindings = [])
    {
        // 设置$useReadPdo = false
        return $this->select($query, $bindings, false);
    }
    
```



#### 2.3、select()方法如何获取写连接
上面我们分别分析到了`useWritePdo()`和`selectFromWriteConnection()`如何调用底层的`select()`方法，并将第三个参数`$useReadPdo`设置为`flase`，达到获取写连接的效果。

那现在让我们一探究竟，`$useReadPdo`是如何影响`select()`获取创建连接类型的呢？
```php
    /**
     * Run a select statement against the database.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @param  bool  $useReadPdo
     * @return array
     */
    public function select($query, $bindings = [], $useReadPdo = true)
    {
        return $this->run($query, $bindings, function ($me, $query, $bindings) use ($useReadPdo) {
            // ...
            // 根据$useReadPdo的值，获取指定类型的数据库连接
            $statement = $this->getPdoForSelect($useReadPdo)->prepare($query);

            $statement->execute($me->prepareBindings($bindings));

            // ...
        });
    }
```
最后再在`getPdoForSelect()`中的一探究竟:
```php
    /**
     * Get the PDO connection to use for a select query.
     *
     * @param  bool  $useReadPdo
     * @return \PDO
     */
    protected function getPdoForSelect($useReadPdo = true)
    {
        return $useReadPdo ? $this->getReadPdo() : $this->getPdo();
    }
```
这就回到了我们在上面分析的结果，初始化时分别将**写连接**保存在`$connection->pdo`中，**读连接**保存在`$connection->readPdo`中，到这里终于打通了任督二脉，最终实现**强制**获取读写连接的效果。


---
### 最后的话
让我在这里老生常谈一下，为什么要看源码吧

一线搬砖的**小兵**，都会有一个成为**建筑大师**，让别人欣赏自己的“作品”的期盼吧。在真正有机会“**设计**”一栋建筑的时候，首先要“**参观**”足够多**著名**的建筑，让自己具备分辨好坏优劣的能力。

说的接地气的一点就是，接了个没有处理过的需求，网上四处问度娘找到多种解决方案，它究竟行不行？不同的情境下究竟该用哪种解决方案更好？如何正确评估影响？不看源码就没有区分的“好坏”的能力，心里总会有一种不踏实的感觉，指不定就是给自己埋了个坑。

最终是为了缓解，自己对未知的焦虑...

