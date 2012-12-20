
## Intro


`crudify` method will automatically create CRUD actions that will map HTTP requests to corresponding methods on given Resource.

<pre>
<b>Request                        Resource</b>
GET     /id                    #get(id)
POST    /   with POST data     #create(params)
PUT     /id with POST data     #get(id).update(params)
PATCH   /id with POST data     #get(id).update(params)
DELETE  /id                    #get(id).delete OR #delete(id)
HEAD    /id                    #get(id)
OPTIONS /                      returns actions available to client
</pre>

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Resource


First argument is required and should provide the CRUDified resource.<br/>
Resource should respond to `get` and `create` methods.<br/>
Objects that will be created/returned by resource should respond to `update` and `delete` methods.

Additionally, your resource may respond to `delete` method.<br/>
If it does, `delete` action will rely on it when deleting objects.<br/>
Otherwise, it will fetch the object by given ID and call `delete` on it.

If your resource/objects behaves differently, you can map its methods by passing them as options.<br/>
Let's suppose you are CRUDifying a DataMapper model.<br/>
To delete an DataMapper object you should call `destroy` on it,
so we simply mapping `delete` action to `destroy` method:

```ruby
crudify ModelName, :delete => :destroy
```

If your resource creating records by `new` instead of `create`,
simply map `post` action to `new` method:

```ruby
crudify ModelName, :post => :new
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Excluded Params

By default all params will be sent to resource.

Good enough, however sometimes you need to exclude some params.

This is easily accomplished by using :exclude option.

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

Each action will respond to corresponding request method.


To route CRUD actions to a different path, simply pass the path as second argument:

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


*IMPORTANT!* The common pitfall here is to define a method that will override 
the actions created by crudifier.

```ruby
class App < E
    map '/'

    crudify SomeModel

    def index
        # Bad Idea!
    end
end
```

The `index` method here will override all actions created by `crudify SomeModel`,
thus CRUD WONT WORK on this controller!

Why so?

Cause actions defined without a verb will listen on all request methods.

So if we define `index` or just `whatever` without `get_`, `post_` etc. prefix,
it will override any actions previously defined with an explicit verb.

```ruby
def get_index
    # ...
end

def post_index
    # ...
end

def index
    # this will OVERRIDE `get_index` and `post_index`
end

def get_read
    # ...
end

def post_read
    # ...
end

def read
    # this will OVERRIDE `get_read` and `post_read`
end
```

In case of CRUD actions, when you need to override some action, define the method with a verb.

For ex. you want "GET /index" requests to be served by your `index` method, 
not by one created by crudifier.

Then you simply define `get_index` method:

```ruby
class App < E
    map '/'

    crudify SomeModel

    def get_index
        # Good Idea!
    end
end
```

*Please Note* that you'll have to name your template "get_index.ext" instead of just "index.ext"


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Response

Crudifier will try to return the value of primary key of extracted/created/updated object.

By default `:id` is used as primary key.

To use a custom primary key, pass it via `:pkey` option:

```ruby
crudify Resource, :pkey => 'prodID'
```

If objects created by your resource does respond to `:[]` and does contain the pkey column, the value of `object[pkey column]` will be returned.


Otherwise if objects created by your resource does respond to pkey column
the value of `object.pkey_column` will be returned.

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

This will return object ID on POST, PUT, and PATCH requests.<br/>

On HEAD requests, the framework is always sending an empty body,
so we only update the headers.<br/>
This way the client may decide when to fetch the object.

On GET requests it will convert object to JSON before it is sent to client.<br/>
Also `content_type` is used to set proper content type.

DELETE action does not need a handler cause it ever returns an empty string.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Error Handler

If your objects responds to `:errors` method, 
crudifier will try to extract and format errors accordingly.

In case of errors, crudifier will behave depending on given options and proc.

If a proc given, crudifier will NOT halt the request.<br/>
It will pass error to given proc via second argument instead.

To halt the request when a proc given, set `:halt_on_errors` to true.

If no proc given, request will be halted unconditionally.

By default the 500 status code will be used when halting.

To use a custom status code pass it via `:halt_with` option.

## Access Restriction


Using `auth` will instruct client to require authorization.<br/>
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

Now, when an client will want to POST, PUT, PATCH, DELETE,
it will be asked for authorization.

And an OPTIONS request will return all actions for authorized clients and
only GET, HEAD, OPTIONS for non-authorized clients.

If an root given, `crudify` will create actions that responds to that root,
thus actions name will contain given root.

In example below, `crudify` will create actions like `get_users`, `post_users`, `put_users` etc.<br/>
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
