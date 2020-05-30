---
title: Laravel DB Eloquent Manual Book
tags: technical
key: a274f7f716d6dec0bbee98605bc364ba
comment: true
article_header:
 type: cover
 image:
  src: /assets/headers/laravel.svg
---
一、入门查询
------------

Laravel应用程序的配置文件放置在config/database中，在其中可以定义各种类型、不同地址的数据库链接，设定默认数据库链接，同事支持在数据库查询动态配置。

------------------------------------------------------------------------

读写分离(本地配置)
------------------

有的时候我们有多台数据库服务器，其中一台用作新增、更新还有删除操作，一台用作读取操作，这个时候就可以通过`read`、`write`很方便的配置数据库的读写分离服务

``` {.php}
'mysql' => [
    'read' => [
        'host' => '192.168.1.1',
    ],
    'write' => [
        'host' => '196.168.1.2'
    ],
    'driver'    => 'mysql',
    'database'  => 'database',
    'username'  => 'root',
    'password'  => '',
    'charset'   => 'utf8',
    'collation' => 'utf8_unicode_ci',
    'prefix'    => '',
],
```

其中，`read`中的`host:192.168.1.1`表示读服务器地址,`write`中的`host:192.168.1.2`表示写服务地址器，可以在`write`、`host`中配置独立的数据库信息，也可以共享使用`mysql`键值下的配置信息
\#\# 基本操作
在设置好数据链接之后，就可以通过`DB`的facade进行数据的库CRUD操作

#### Select

使用`DB`的facade进行`select`操作

##### 参数绑定

``` {.php}
// namespace .....
use DB;
use App\Http\Controller\Controller;

class IndexController extends Controller
{
    public function index()
    {
        $users = DB::select('select * from users where active = ?', [1]);
        
        return view('index/users', ['users' => $users]);
    }
}
```

在使用原始SQL查询时，使用参数绑定可以防止SQL注入
`select`方法的返回值是数组，数组中的变量类型是`StdClass`，可以使用以下方式获取所有结果

``` {.php}
foreach($users as $user) {
    $user->name; // 访问user表中的name字段值
}
```

##### 命名绑定

除了使用`?`符号将参数按照排列顺序绑定外，还可以使用`命名`的方式对参数进行绑定

``` {.php}
DB::select('select * from users where active = :active', ['active' => 1]);
```

#### 增删改（update insert delete statement）

##### insert

若要运行 `insert` 语法，则可以在 DB facade 使用 `insert` 方法。如同
`select` 一样，这个方法的第一个参数是原始的 SQL
查找，第二个参数则是绑定：

    DB::insert('insert into users (id, name) values (?, ?)', [1, 'Dayle']);

##### update

`update`
方法用于更新已经存在于数据库的记录。该方法会返回此声明所影响的行数：

    $affected = DB::update('update users set votes = 100 where name = ?', ['John']);

##### delete

`delete` 方法用于删除已经存在于数据库的记录。如同 `update`
一样，删除的行数将会被返回：

    $deleted = DB::delete('delete from users');

##### command

有时候一些数据库操作不应该返回任何参数。对于这种类型的操作，你可以在 DB
facade 使用 `statement` 方法：

    DB::statement('drop table users');

#### sql语句监听

``` {.php}
DB::listen(function($sql, $bindings, $time) {
    //
 });
```

#### 数据库事务

##### 自动事务

``` {.php}
DB:transaction(function(){
    
});
```

##### 手动事务

``` {.php}
DB::beginTransaction()

DB::rollBack()

DB::commit()
```

##### 多数据库连接

``` {.php}
DB::connection()
```

二、查询构造器
--------------

### 获取结果

-   所有结果

`DB::table('user')->get()`，返回结果为StdClass类型

-   单个结果

`DB::table('user')->first()`

-   单条记录单个值

`DB::table('user')->value()`

-   多条记录单个值

`DB::table('user')->lists('name')`

-   数据结果切块

`DB::table('user')->chunk(100,  function($user) {  })`，返回false中断后续处理

-   字段值列表

`DB::table('user')->pluck('title') // 单值列表`

`DB::table('user')->pluck('title', 'name') // 多值列表`

-   聚合结果

sum、count、max、min、avg

### 指定获取字段（selects）

select值（别名)：

``` {.php}
$users = DB::table('users')->select('name', 'email as user_email')->get();
```

添加查询select:

`$query = DB::table('users')->select('name');`

结果去重：

`$users = DB::table('users')->distinct()->get();`

原始表达式：

禁止用户输入作为动态内容

``` {.php}
$users = DB::table(‘users’)->select(DB::raw(‘count() as user_count, status’))
  ->where(‘status’, ‘<>’, 1)
  ->groupBy(‘status’)
  ->get();
```

### Joins

#### inner join\[内连接\]

``` {.php}
$users = DB::tables('users')
->join('contacts', 'users.id', '=', 'contacts.user_id')
->join('orders', 'users.id', '=', 'orders.user_id')
->select('users.', 'conatact.phone', 'orders.price')
->get();
```

#### left join\[左连接\]

``` {.php}
$users = DB::tables('users')
  ->leftJoin('contacts', 'users.id', '=', 'contacts.user_id')
  ->get();
```

#### cross join\[全连接\]

``` {.php}
$users = DB::tables('users')
  ->crossJoin('orders', 'users.id', '=', 'orders.user_id')
  ->get();
```

#### 高级join(连接中使用where查询条件)

``` {.php}
$users = DB::table('users')
    ->leftJoin('contacts', function($join) {
        $join->on('users.id', '=', 'contacts.user_id')
            ->whereNull('contacts.deleted_at')
    })
    ->get();
```

where子句

简单的where查询：

简单方式，where('待查询字段', '比较值')，默认运算符为：=

``` {.php}
$users = DB::table('users')
    ->where('id', 1)
    ->get();
```

运算符方式，where('待比较字段', '运算符', '比较值')

``` {.php}
$users = DB::tables('users')
    ->where('id', 'in', [1, 2, 3])
    ->get();
```

运算符还可以为，>、<、=、like...等

Or查询：

orWhere和where接受一样的参数，支持链式调用

``` {.php}
$users = DB::tables('users')
    ->where('address', 'in', ['guangdong', 'hubei'])
    ->orWhere('active', 1)
    ->get();
```

其他类型的where查询（简单where查询的便捷方式）：

whereBetween

whereNotBetween

whereIn

whereNotIn

whereNull

whereNotNull

whereColumn

简单方式，比较两列值相等

``` {.php}
$users = DB::table('users')
    ->whereColumn('created_at', 'updated_at')
    ->get();
```

特别方式，支持数据查询条件（数组列表之间使用and连接）

``` {.php}
$users = DB::tables('users')
    ->whereColumn([
        ['created_at', 'updated_at'],
        ['']
    ])
```

高级where子句

参数分组：

where子句嵌套查询（支持and和or嵌套的复杂查询）

``` {.php}
DB::table('users')
    ->where('name', '=', 'John')
    ->orWhere(function($query) {
        $query->where('votes', '>', '100')
      ->where('titles', '<>', 'Admin')
    })
```

实际结果如下：

``` {.php}
select  from users where name = 'John' or (votes > 100 and title <> 'Admin')
```

Exists语法：

whereExists允许编写where exists的SQL子句

``` {.php}
$users = DB::table('users')
    ->whereExists(function($query) {
        $query->select(DB::raw(1))
            ->from('orders')
            ->where('orders.users_id', '=', 'users.id');
    })->get();
```

``` {.sql}
select  from users where exists (
  select 1 from orders where users.id = orders.user_id
)
```

TODO：In查询：

简单In查询，可以使用PHP代码嵌套查询；复杂的In查询，该怎么处理？

JSON查询语句(MySQL 5.7以上版本才支持)

略...

Ordering、Grouping、Limit及Offset

orderBy:

简单的单列查询条件排序

``` {.php}
$users = DB::table('users')
    ->orderBy('name', 'desc')
    ->get(); 
```

inRandomOrder:

随机选择查询结果

``` {.php}
$users = DB::table('users')
    ->inRandomOrder()
    ->first();
```

groupBy、having、havingRaw:

ps:having子句必须是对group by中出现的列或者是配合聚合函数一起使用。

skip&take：

查询结果偏移，以及获取指定的数据条数：

``` {.php}
$users = DB::table('users')
    ->skip(10)
    ->take(5)
    ->get();
```

条件查询

当when里面条件参数第一次为true时，where条件才会执行：

eg：当用户选择了\$role查询条件时，添加role过滤条件

``` {.php}
$role = $request->get('role');

$users = DB::tables('usres')
    ->when($role, function($query) use ($role) {
       return $query->where('role', $role);
    })
    ->get();
```

ps：备注，\$query结果需要返回

Inserts

可以使用数组的方式批量插入数据：

``` {.php}
DB::table('users')->insert([['email' => '123@123.com'], ['email' => '34@54.com']]);
```

自动递增ID：

获取插入数据的ID

``` {.php}
DB::table('users')->insertGetId(['email' => '234@qq.com']);
```

Updates

``` {.php}
DB::table('users')
            ->where('id', 1)
            ->update(['votes' => 1]);
```

递增或递减

``` {.php}
DB::table('users')->increment('vote');
DB::table('users')->decrement('vote');
DB::table('users')->increment('vote', 5);
DB::table('users')->decrement('vote', 5);
```

Deletes

删除指定记录：

``` {.php}
DB::table('users')->where('votes', '<', 100)->delete();
```

删除表格所有记录，并且自增ID重新设为0：

``` {.php}
DB::table('users')->truncate();
```

悲观锁

在查找上使用悲观锁，可以避免数据被更改，直到事务被提交为止：

``` {.php}
DB::table('users')->where('votes', '<>', 100)->sharedLock();
```

或者使用排他锁:

``` {.php}
DB::table('users')->where('votes', '<>', 100)->lockForUpdate()->get();
```

三、Eloquent ORM
----------------

### Model配置项

``` {.php}
// 表名(默认蛇形名称)
protected $table = 'users';   

// 主键（默认ID）
protected $primaryKey = '';

// 时间戳（默认为true， 自动维护created_at, updated_at）
protected $timestamps
    
// 数据连接
protected $connection
    
// 白名单(可以被赋值的属性)
protected $fillable = ['name']    

// 黑名单（禁止被赋值的属性）
protected $guarded = ['created_at', 'updated_at'];

// 日期属性
protected $dates = ['deleted_at'];

// 
```

TODO 验证如果创建表结构的时候不添加on update
current\_timestamp，分别使用DB方法，还有Model方法是否自动维护这两个字段。

### CRUD

#### 数据查询

##### 取回多个值

使用all方法，取回所有模型(去除被软删除的数据)

``` {.php}
$flights = Flight::all();
```

通过访问类属性方式，访问字段值

``` {.php}
foreach($flights as $flight) {
    $name = $flight->name; // 获取航班名称
}
    
```

-   增加额外限制

复杂的模型查询可以参考\[查询构造器\]

TODO 跳转查询构造器

-   集合

使用all()或者get()返回的结果为\Illuminate\Database\Eloquent

Collection实例，使用可参考\[collection辅助函数\]

TODO 跳转collection辅助函数

-   分块

和查询构造器一样，当处理大批量数据的时候可以使用chunk方法对数据进行拆分，将结果放入闭包进行批量处理（每个chunk为一个请求）

`Flight::where('date', '2020-04-05')       ->chunk(100, function($flights) {           // 数据处理       });`

-   游标（）

对于更大批量的读取，使用cursor能大幅度减少内存的使用

`foreach(Flight::where('date', '2020-04-15')->cursor() as $flight) {       // $flight 数据处理   }`

##### 取回单个值/模型

-   单个值

可以通过主键（默认ID）的方式查找单条数据

`$flight = Flight::find(1);`

可以通过where查询条件，然后对查询结果进行排序处理，取出其中的第一条数据

`$flight = Flight::where('active', 1)->first();`

**\[未找到\]异常**

找不到模型时抛出异常，在路由和控制器中特别有用，`findOrFail`和`firstOrFail`在找不到模型时会抛出`Illument\Database\Eloquent\ModelNotFoundException`，若未捕捉异常，则会自动返回404错误

```php
$flight = Flight::where('name', 'south')->firstOrFail();

$flight = Flight::findOrFail();
```

-   取回集合

可以使用查询构造器提供的聚合函数（包括sum、max、min、count、avg等），返回查询结果适当的标量值（而不是模型）

`php   // 取出所有状态为1的航班数量   $count = Flight::where('active', 1)->count();`

#### 添加和更新模型

##### 基本添加

创建模型，设置属性然后调用save方法保存，即可添加一条记录

``` {.php}
$flight = new Flight();
$flight->name = $request->name;
$fiight->save();
```

##### 基本更新

首先要取回模型，然后修改属性，最后调用save方法保存修改

``` {.php}
$flight = Flight::where('date', '2020-04-16')->first();
$flight->date = Carbon::now()->toDateString();
$flight->save();
```

##### 批量赋值

将属性用数组的方式作为参数，调用create方法（需要配合$fillable白名单或者$guarded黑名单避免遭受批量赋值漏洞）

``` {.php}
class Flight extends Model
{
    // 可以被批量赋值的属性
    protected $fillable = ['name'];
}
//返回保存的结果
$res = Flight::create(['name' => 'flight 10']);
```

##### 其他创建方法

用指定的数据从数据库中查找值，如果未找到则会创建一条记录，其中有firstOrNew()和firstOrCreate()方法，其中firstOrNew()返回的模型还没有保存到数据库，不要手动执行save()操作才会在数据库生效。

``` {.php}
// 用属性获取模型，如果不存在则创建
$flight = Flight::firstOrCreate(['name' => 'flight 01']);

// 用属性获取模型，如果不存在则创建实例，需要用save()方法创建实例
$flight = Flight::firstOrNew(['name' => 'flight 01']); 
$flight->save();
```

#### 删除模型

基本方式删除，对模型实例使用delete（）方法，删除该记录

##### 模型删除

``` {.php}
$flight = Flight::find(1);

$flight->delete();
```

##### 键删除

如果知道主键，可以省去查找数据并实例化的过程

``` {.php}
// 单条/多条删除
Flight = destroy([1, 2]);
```

##### 查找删除

``` {.php}
$deleteRow s = App\Flight::where('active', 0)->delete();
```

#### 软删除

##### 判断是否软删除

``` {.php}
if ($flight->trashed) {
    // todo
}
```

##### 查找被删除的模型

``` {.php}
$flights = App\Flight::withTrashed()
    ->where('isActive', 1)
    ->get();
```

##### 取出被删除模型

``` {.php}
$flights = App\Flight::onlyTrashed()
    ->where('isActive', 1)
    ->get();
```

##### 恢复被删除模型

在模型上恢复，使用restore方法

``` {.php}
// 单条数据
$flight->restore();

// 多条数据
App\Fligth::withTrashed()
    ->where('isActive', 1)
    ->resotre();
```

##### 永久删除模型

``` {.php}
// 单挑数据
$flight-forceDelete();
```

### 查询作用域

#### 全局作用域

给定模型的所有查询条件添加约束，软删除操作就是运用全局作用域取出没有被删除的模型

##### 编写作用域

首先需要实现`Illuminate\Database\Eloquent\Scope`接口的类，实现其中的apply方法，在其中增加where条件

``` {.php}
<?php

use Illument\database\Eloquent\Scope;

class AgeScope implements Scope
{
    public function apply(Builder builder, Modal $modal)
    {
        return $builder->where('age', '>', 10);
    }
}
```

##### 应用作用域

给指定模型添加作用域

``` {.php}
<?php

class User extends Model
{
    protected static function boot()
    {
        parent::boot();
        staic::addGlobalScope(new AgeAcope);
    }
}
```

应用效果，使用`Age::all()`后的效果如下

``` {.php}
select  from `users` where `age` > 10
```

##### 匿名作用域

支持使用闭包创建全局作用域，针对简单的规则十分有效，无需创建单独的作用域文件

``` {.php}
class User Extends Model
{
    protected static function boot()
    {
        parent::boot();
        
        static::addGlobalScope('age', function(Builder $builder){
            $builder->where('age', '>', 10);
        })
    }
}
```

使用方式与显式定义一样，不做特殊说明

##### 移除作用域

移除匿名作用域

``` {.php}
User::withoutGlobalScope('age')->get();
```

移除显式创建的作用域

``` {.php}
User::withoutGlobalScope(AgeScope::class)->get();

//移除所有作用域
User::withoutGlobalScope()->get();

// 移除多个指定的全局作用域
User::withoutGlobalScope([FistScope::class, second::class])
```

#### 本地作用域

##### 利用范围查找

模型中定义约束集合进行复用，只需要在模型方法前添加scope前缀，并且返回查询构造器即可

``` {.php}
class User extends Model
{
    public function scopePopular($query)
    {
        return $query->where('votes', '>', 10);
    }
}
```

使用

``` {.php}
User::popular()->orderBy('votes', 'desc')->get();
```

##### 动态范围

允许定义可接受参数的范围，只需要在定义的时候添加参数即可

``` {.php}
class User extends Model
{
    public function scopeOfType($query, $type)
    {
        return $query->where('type', $type);
    }
}
```

现在，可以在使用范围的时候传递参数

``` {.php}
$users = User::ofType('admin')->get();
```

### 事件

Eloquent模型会触发很多事件，可以借助以下时间在模型的多个生命周期进行监控

创建(creating, created)、更新(updating, updated)、保存(saving,
saved)、删除(deleting, deleted)、恢复(restoring, restored)

第一次保存模型时会触发creating、created方法，如果一个模型已存在数据库，然后调用save方法，就会触发updating、updated方法，以上两种情况都会触发saving、saved方法

在AppServiceProvider中定义Eloquent事件监听器

四、Eloquent：关联
------------------

### 定义关联

可以在Eloquent模型中将关联定义为函数，函数的调用支持Eloquent链式查询构造器

``` {.php}
$user->posts()->where('active', 1)->get();
```

#### 常用关联

##### 一对一

User模型对应一个Phone，可以通过在将phone方法添加在User上来定义这种关联，并且在phone方法中返回基类的hasOne方法的结果

``` {.php}
class User Extends Model
{
    public function phone()
    {
        return $this->hasOne(Phone::class);
    }
}
```

`hasOne()`方法的第一个参数为模型名称，定义好关联之后我们就可以使用动态属性来获取关联的模型

``` {.php}
$phone = User::find(1)->phone();
```

`hasone()`方法的第二个参数为外键名称，约定该值为`关联模型小写_id`的方式，这里默认`Phone`模型有user\_id的外键指向User模型

``` {.php}
return $this->hasOne(Phone::class, 'foreign_key')
```

同时，`Phone`模型的外键`user_id`会默认关联上层模型（User）模型的主键，这里约定默认为`id`字段，可以传入第三个参数用来指定自定义的键值

``` {.php}
return $this->hasOne(Phone::class, 'foreign_key', 'local_key');
```

**定义相对的关联**

以上定义可以从User模型访问Phone模型，有的时候需要执行相反的操作，这个时间可以在Phone模型上定义belongsTo方法，将User模型关联到Phone上

``` {.php}
class Phone extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

上述模型中，约定使用`Phone`模型的`user_id`字段关联上层的模型User的`id`字段，当Phone模型的外键不为user\_id时，可以通过传入第二个参数自定义关联外键

``` {.php}
return $this->belongsTo(User::class, 'foreign_key');
```

其中，若上层模型User中的主键不是id时，可以通过传入第三参数，指定要关联的上层模型主键

``` {.php}
return $this->belongsTo(User::class, 'foreigh_key', 'other_key');
```

##### 一对多

一对多模型关联应用于一个模型拥有任意数量的其他关联模型，就像一篇博客文章可以有无限多个评论。可以通过在模型中定义一个如下函数表达这种关系

``` {.php}
class Post extends Model
{
    public function comments()
    {
        return $this->hasMany('App\Comment');
    }
}
```

其中Eloquent会自动判断`Comment`关联模型的外键为上层模型名称的\[蛇形命名\]加`_id`，这里`Comment`中的外键为`post_id`。

一但定义好关联，就可以通过`$post->comments`动态属性的方式访问关联模型，还给关联模型添加额外查询条件，如下

``` {.php}
$post->comments()->where('active', 1)->orderBy('id, 'desc')->get();
```

对于未按照默认方式命名的模型，函数的第二个参数可以用来设置关联上层模型的外键，第三个参数用来指定上层模型的主键

``` {.php}
return $this->hasMany('App\Comments', 'foreign_key');

return $this->hasMany('App\Comments', 'foreign_key', 'local_key');
```

*定义相对的关联*

上面通过`comments`方法可以访问关联模型，那么可以通过在下层模型中定义相对的关联，实现从`Comment`访问关联的`Post`模型，需要在下层模型的函数中调用`belongsTo`方法进行关联

``` {.php}
class Comment extends Model
{
    /*
    * 获得拥有该评论的文章
    */
    public function post()
    {
        return $this->belongs('App\Post');
    }
}
```

其第二个参数和第三个参数与上面[一对多](#一对多)中`hasMany()`函数中定义的一致

##### 多对多

多对多关联，就比如每个用户可以有多种角色，每个角色都可以有多种角色，这里涉及到`users`、`roles`、`role_user`三张表，默认`role_user`表名的命名是两个表名关联命名，其中包含两张表的主键`user_id`、`post_id`。要定义这种关系，我们可以通过`belongsToMany()`方法

``` {.php}
class User Extends Model
{
    // 用户拥有的角色
    public function roles()
    {
        return $this->belongsToMany('App\Role');
    }
}
```

一旦定义好，就可以通过以下方式调用

``` {.php}
$user = App\User::find(1);

foreach($user->roles as $role) {
  // $role...
}
```

同样可以调用函数进行关联查询

``` {.php}
$user->roles()->where('level', '>', '2')->get();
```

其中，对于未按照默认规范命名的多对多模型关联，在使用的时候也可以指定表名和模型关联外键

``` {.php}
return $this->belongsToMany('App\Role', 'role_user', 'user_id', 'post_id');
```

*定义相对的关联*

方式与上面一致，同样使用`belongsToMany()`方法，具体的写法如下

``` {.php}
class Role extends class
{
    // 访问拥有该角色的用户
    public function users()
    {
        return $this->belongsToMany('App\User');
    }
}
```

其中，对于未按照默认规范命名的多对多模型关联，在使用的时候可以指定表名和模型关联外键

``` {.php}
return $this->belongsToMany('App\User', 'role_user', 'role_id', 'user_id');
```

*特别注意*，这里`第三个参数`和`第四个参数`与上面[多对多](#多对多)中相反

**获取中间表数据**

对于多对多关联，有时需要操作中间的关联表，这个时候可以使用`pivot`属性。例如，假设`User`模型多对多关联`Role`模型对象，我们可以进行如下操作获取中间表数据

``` {.php}
$user = App\User::find(1);

foreach($user->roles as $role) {
    $role->pivot->created_at;
}
```

Eloquent默认每个取出来的`Role`模型都包含`pivot`属性，但是只提供模型的键值，如果需要访问其他的属性，可以在定义多对多关联时通过如下方式指定

``` {.php}
return $this->belongsToMany('App\Role')->withPivot('column1', 'column2');
```

也可以在定义多对多模型的时候调用`withTimestamps()`方法，自动维护`updated_at`,
`created_at`字段

``` {.php}
return $this->belongsToMany('App\Role')->withTimestamps();
```

**使用中间表来过滤关联数据**

可以通过添加`wherePivot()`和`wherePivotIn()`方法，对中间关联模型进行过滤

``` {.php}
return $this->belongsToMany('App\Role')->wherePivot('status', 1);

return $this->belongsToMany('App\Role')->wherePivotIn('status', [1, 2]);
```

### 关联查找（重要，性能优化）

所有类型的Eloquent关联都提供[查询构造器](#二、查询构造器)的功能，让你在真正查询数据库前，在关联查找后面添加查询条件

还是假设博客系统，`User`模型拥有很多关联的`Post`模型：

``` {.php}
class User extends Model
{
    // 关联的文章数据
    public function posts()
    {
        return $this->hasMany('App\Post');
    }
}
```

可以在`User`模型查找`posts`关联时，添加附加过滤条件

``` {.php}
$user = App\User::find(1);

$posts = $user->posts()->where('active', 1)->get();
```

这里支持***查询构造器的所有语法***

##### 关联方法与动态属性

如果不需要增加额外的条件至Eloquent关联查找，可以简单的像访问属性一样访问关联

``` {.php}
$user = App\User::find(1);

foreach($user->posts as $post) {
    // $post...
}
```

##### 查找关联是否存在

在访问关联之前，可以通过`has()`方法判断是否存在

``` {.php}
// 查找至少有一个评论的文章
$posts = App\Post::has('comments')->get();

// 也可以添加运算符，自定义判断条件
$posts = App\Post::has('comments', '>', 1)->get();

// 还可以支持嵌套查询 ...
```

更高级的方式可以使用`whereHas`、`orWhereHas`方法，可以通过在`has`中添加`where`方法，增加自定义查询条件至关联查询中，例如检查文章评论包含指定内容

``` {.php}
$posts = App\Post::whereHas('comments', function($query) {
    $query->where('content', 'like', '%love%');
})->get();
```

可以用来比较过滤条件应用在关联模型上的查询，以及***跨数据库关联***查找

##### 关联数据计数

针对如果想要获取关联模型的数量但是又不想单独发送Sql请求时，可以使用`withCount`方法，获取关联数量，并将结果保存至`{attribute}_count`的属性中

``` {.php}
// 使用一个Eloquent关联查询获取文章评论数
$posts = App\Post::withCount('comments')->get();

foreach($posts as $post) {
   $posts->comments_count;
}
```

还可以在关联计数查询中添加限制过滤条件

``` {.php}
// 获取文章投票数，以及包含win关键字的评论数
$posts = App\Post::hasWhere(['votes', 'comments' => function($query) {
    $query->where('content', 'like', '%win%');
}]);
```

### 预加载

在不做任何处理的情况下，通过属性访问Eloquent关联时，该关联数据会被\[延迟加载\]，只有在使用属性的才会加载。同时，Eloquent可以在查找上层模型时进行预加载，这样就可以避免*N+1查找*问题

例如，这里假设上层模型`Author`关联`Book`

``` {.php}
class Book extends Model
{
    public function authors()
    {
        return $this->belongsTo('App\Author');
    }
}
```

通常我们获取图书作者信息时采用以下方式

``` {.php}
// step 1
$books = App\Book::all();

// step2
foreach($books as $book) {
    // 获取作者姓名
    $book->author->name;
}
```

这里假设有25本书，`step1`执行1次数据库查询，然后`step2`遍历执行25遍查找，所以这里实现需求一共执行了26次查找，这就是N+1查找问题。

幸运的是，我们可以通过预加载的方式将查询优化至2次，其中用到`with`方法提前预加载关联的属性

``` {.php}
$books = App\Book::with('author')->get();

foreach($books as $book) {
    echo $book->author->name;
}
```

对于该操作，实际只运行两次查找

``` {.php}
select * from books;

select * from authors where id in (1, 2, 3, 4, 5....);
```

#### 预加载多个关联

``` {.php}
$books = App\Book::with('author', 'publisher')->all();

foreach($books as $book) {
    $book->author->name;
    $book->publisher->name;
}
```

#### 嵌套预加载

若要预加载关联，可以使用点语法，如预加载作者的联系方式相关信息

``` {.php}
$books = App\Book::with('author.contacts')->get();
```

#### 预加载条件限制

预加载查询支持添加查询条件限制

``` {.php}
$users = App\User::with(['posts' => function($query) {
    $query->where('active', 1)->orderBy('created_at', 'desc');
}]);
```

#### 延迟预加载

可以在上层查询获取之后，才进行关联模型的预加载，或者是在前置动态条件满足的情况下才会进行预加载，此时可以使用Eloquent的`load`方法

``` {.php}
$books = App\Book::all();

if (some_condition == true) {
    $books->load('author');
}
```

`load`延迟预加载同样支持*多属性*、*限制条件*、*嵌套*等操作

### 写入关联模型

#### 一多一、一对多

##### save方法

Eloquent提供便捷的方法来将新的模型添加到关联中，通常我们为了将`comment`关联`post`，需要手动保存post\_id信息，通过关联模型的save方法既可以轻松保存数据并且创建关联

``` {.php}
// 保存单个关联模型
$comment = new App\Comment(['message' => 'A new comment.']);
$post = App\Post::find(1);
$post->comments()->save($comment);

// 保存多个关联模型
$post->comments()->saveMany(
  ['content' => 'comment from A' ],
    ['content' => 'comment from B']
)
```

##### create方法

允许通过原始数组的方式保存新数据

``` {.php}
$post = App\Post::find(1);

$comment = $post->comments()->create(['content' => 'comment from C']);
```