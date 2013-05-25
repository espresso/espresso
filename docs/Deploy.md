
## Controllers

Run a single controller app:

```ruby
class App < E
  # ...
end

App.run

# or
app = App.mount do
  # some setup
end
app.run

# or create a new app and mount controller
app = E.new
app.mount App do
  # some setup
end
app.run
```

Controllers can be also mounted by using Regexps:

```ruby
app = E.new
app.mount /SomeController/
# etc.
app.run
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Slices

Slices are used to bundle, setup and run a set of controllers.

A Espresso Slice is nothing more than a Ruby Module.

That's it, to create a slice simply wrap your controllers into a module:


```ruby
require 'e'
require 'e-ext' # needed for Forum.run and Forum.mount to work

module Forum
  class Users < E
    # ...
  end
  class Posts < E
    # ...
  end
end

Forum.run  # running Forum Slice directly

# creating a new app from Forum Slice
app = Forum.mount do 
  # some setup
end
app.run

# or create a new app and mount the slice
app = E.new
app.mount Forum do
  # some setup
end
app.run
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Automount

By using automount you do not need to mount controllers manually.

To make newly created app to automount all found controllers, pass `true` as first argument:

```ruby
app = E.new(true)
```

If you want to automount only controllers contained into some namespace, use that namespace as first argument:

```ruby
module Frontend
  class Pages < E
    # ...
  end

  class News < E
    # ...
  end
end

module Admin
  class Pages < E
    # ...
  end

  class News < E
    # ...
  end
end
app = E.new(Frontend)
```

this will automount only controllers under `Frontend` module, leaving you to mount `Admin` controllers manually.

Namespace can also be provided as a regular expression:

```ruby
module Frontend
  class Pages < E
    # ...
  end

  class News < E
    # ...
  end
end

module Admin
  class Pages < E
    # ...
  end

  class News < E
    # ...
  end
end
app = E.new(/Pages/)
```

this will automount `Frontend::Pages` and `Admin::Pages`

If you need some controller(s) to not be automounted, use `reject_automount!` method inside controller class:

```ruby
class Pages < E
  # ...
end

class News < E
  reject_automount!
  # ...
end

app = E.new(true)
```

this will automount `Pages` controller but not `News`


## Mount Root


To mount a controller/slice into a specific root, pass it as a `String`:

```ruby
module Forum
  class Users < E
    # ...
  end
  class Posts < E
    # ...
  end
end

app = Forum.mount('/forum')
app.run

# or
app = E.new
app.mount(Forum, '/forum')
app.run
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Arbitrary Applications

Espresso allow to mount any Rack-compatible application same way as usual controllers/slices mounted.

**Example:** mount `SomeSinatraApp` into "/"

```ruby
E.new do
  mount SomeSinatraApp
end
```

**Example:** mount `SomeSinatraApp` into "/blog"

```ruby
E.new do
  mount SomeSinatraApp, "/blog"
end
```

By default, mounted applications will respond to any request method.

To make it respond only to some request method(s), use `:on` option:

**Example:** make `SomeSinatraApp` to respond only to specific requests

```ruby
E.new do
  mount SomeSinatraApp, on: :get
  # or
  mount SomeSinatraApp, on: [:get, :post]
  # or
  mount SomeSinatraApp, request_method: :get
  # or
  mount SomeSinatraApp, request_methods: [:get, :post]
end
```

Worth to note that mounted applications will honor host politics:

**Example:** `SomeSinatraApp` will respond only to requests originating on default host and `site.com`

```ruby
E.new do
  map host: 'site.com'
  mount SomeSinatraApp
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Run


By default Espresso will run `WEBrick` server on `5252` port.

To run another server/port, use `:server`/`:port` options.

If given server requires some options, pass them next to `:server` option.

**Example:** Use Thin server on its default port

```ruby
app.run :server => :Thin
```

**Example:** Use EventedMongrel server with custom options

```ruby
app.run :server => :EventedMongrel, :port => 9090, :num_processors => 100
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## config.ru


Running a single controller:

```ruby
require 'your-app-file(s)'

run MyController
```

Running a Slice:

```ruby
require 'your-app-file(s)'

run MySlice
```

Running an app instance:

```ruby
require 'your-app-file(s)'

app = MyController.mount

# or create a new Espresso application using `E.new`
app = E.new :automount  # will auto-discover all available controllers

run app
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
