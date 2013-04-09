## Intro

`crudify` method will automatically create CRUD actions that will map HTTP requests to corresponding methods on given Resource.

<pre>
<b>Request                      Resource</b>
GET     /id                  #get(id)

POST    /   with POST data   #create(params)

PUT     /id with POST data   #get(id).update(params) for DataMapper
                             #get(id).update_attributes(params) for ActiveRecord

PATCH   /id with POST data   #get(id).update(params) for DataMapper
                             #get(id).update_attributes(params) for ActiveRecord

DELETE  /id                  #get(id).destroy

HEAD    /id                  #get(id)

OPTIONS /                    returns actions available to client
</pre>

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Resource


First argument is required and should provide the CRUDified resource.<br>
Resource should respond to `get` and `create` methods.<br>
Objects created/returned by resource should respond to `update`/`update_attributes` and `destroy` methods.

If your resource/objects behaves differently, you can map its methods by passing them as options.<br>

**Example:** - Force destroying objects

```ruby
crudify ModelName, :delete => :destroy!
```

**Example:** - Using a resource that creating records by `new` instead of `create`

```ruby
crudify ModelName, :post => :new
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Excluded Params

By default all params will be sent to resource.

Good enough, however sometimes you need to exclude some of them.

This is easily accomplished by using `:exclude` option.

To exclude a single param, pass it as a string.

```ruby
crudify Resource, :exclude => '__stream_uuid__'
```

To exclude multiple params, pass them as an array.

```ruby
crudify Resource, :exclude => ['__stream_uuid__', 'user']
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Root


By default, `crudify` will create actions that respond to controllers root path.

```ruby
class App < E
  map '/'

  crudify SomeModel
end
```

This will create following actions:

    - get_index
    - head_index
    - post_index
    - put_index
    - patch_index
    - delete_index
    - options_index


To route CRUD actions to a different path, simply pass it as second argument:

```ruby
class App < E
  map '/'

  crudify UsersModel, :users
end
```

This will create following actions:

    - get_users
    - head_users
    - post_users
    - put_users
    - patch_users
    - delete_users
    - options_users


**IMPORTANT!** When you need to override some CRUD action, define it using the corresponding verb.<br>
Verbless actions will have no effect cause **verbified actions has priority over verbless ones, regardless definition order**:

```ruby
class App < E
  map '/'

  crudify SomeModel

  def index
    # will have no effect at all
  end

  def get_index
    # will override crudified method that responds to GET requests
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Response

Crudifier will try to return the value of primary key of extracted/created/updated object.

By default `:id` is used as primary key.

To use a custom primary key, pass it via `:pkey` option:

```ruby
crudify Resource, :pkey => 'prodID'
```

If objects created by your resource does respond to `:[]` and does contain the pkey column, the value of `object[pkey column]` will be returned.

Otherwise if objects created by your resource does respond to a method of same name as `pkey`,
the value of `object.send(pkey)` will be returned.

Otherwise the object itself will be returned.

However, if you have a custom logic rather than simply return primary key, use a block.

The block will receive the object as first argument:

```ruby
crudify UsersModel do |obj|
  case
    when post?, put?, patch?
      obj.id
    when head?
      last_modified obj.last_modified
    else
      content_type '.json'
      obj.to_json
  end
end
```

This will return object ID on POST, PUT, and PATCH requests.<br>

On HEAD requests, the framework is always sending an empty body,
so we only update the headers.<br>
This way the client may decide when to fetch the object.

On GET requests it will convert the object to JSON before it is sent to client.<br>
Also `content_type` is used to set proper content type.

DELETE action does not need a handler cause it ever returns an empty string.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Error Handler

If your objects responds to `:errors` method, 
crudifier will try to extract and format errors accordingly.

In case of errors, crudifier will behave depending on given options and proc.

If a proc given, crudifier will NOT halt the request.<br>
It will pass error to given proc via second argument instead.

To halt the request when a proc given, set `:halt_on_errors` to true.

If no proc given, request will be halted unconditionally.

By default the 500 status code will be used when halting.

To use a custom status code pass it via `:halt_with` option.

## Access Restriction


Using `auth` will instruct client to require authorization.<br>
Access can be restricted to some or all actions.

In example below we will restrict access to Create, Update and Delete actions:

```ruby
class App < E
  # ...

  auth :post_index, :put_index, :patch_index, :delete_index do |user, pass|
    [user, pass] = ['admin', 'someReally?secretPass']
  end

  crudify ModelName
end
```

Now, when the client will want to POST, PUT, PATCH, DELETE,
it will be asked for authorization.

And an OPTIONS request will return all actions for authorized clients and
only GET, HEAD, OPTIONS for non-authorized clients.

If a root path given, `crudify` will create actions that responds to that root,
thus actions name will contain given root.

In example below, `crudify` will create actions like `get_users`, `post_users`, `put_users` etc.<br>
That's why we should specify proper action name in `auth` for authorization to work:

```ruby
class App < E
  # ...

  auth :post_users, :put_users, :patch_users, :delete_users do |user, pass|
    [user, pass] = ['admin', 'someReally?secretPass']
  end

  crudify UsersModel, :users
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
