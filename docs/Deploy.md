
## Controllers

Run a single controller app:

```ruby
class App < E
    # ...
end

App.run

# or
app = App.mount
app.run

# or create a new app and mount controller
app = EApp.new
app.mount App
app.run
```

Controllers can be also mounted by given name rather than by class.

This turn to be useful when you do not want or can't wrap controllers into slices,
meant they are not under same namespace.

Name can be provided as a string, symbol or regex.

```ruby
app = EApp.new false
app.mount 'SomeController'
app.mount 'SomeAnotherController'
app.mount :NotAnotherController
app.mount /Controller/
# etc.
app.run
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Slices


Wrap the app into a slice(module) and run:

```ruby
module Forum
    class Users < E
        # ...
    end
    class Posts < E
        # ...
    end
end

Forum.run

# or
app = Forum.mount
app.run

# or create an app and mount the slice
app = EApp.new
app.mount Forum
app.run
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Roots


To mount a controller/slice into a specific root, pass it as first argument:


```ruby
module Forum
    class Users < E
        # ...
    end
    class Posts < E
        # ...
    end
end

app = Forum.mount '/forum'
app.run

# or
app = EApp.new
app.mount Forum, '/forum'
app.run
```

If controller/slice should serve multiple roots, pass them all as arguments:

```ruby
app = Forum.mount '/forum', '/Forums'
app.run

# or
app = EApp.new
app.mount Forum, '/forum', '/Forums'
app.run
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Inner Apps

As of version 0.3.3 Espresso supports mounting of any Rack app.

Just mount it as a regular Espresso controller.

**Example:** Mounting a Sinatra app:

```ruby
require 'sinatra/base'
require 'e'

class Cms < Sinatra::Base

  get('/') { 
    # ...
  }

  # ...

end

class App < E
  map '/'

  def index
    # ...
  end

  # ...
end

app = EApp.new do
  
  mount App          # this will mount App into /
  mount Cms, '/cms'  # this will mount Sinatra app into /cms
end
app.run
```

And of course inner apps supports canonical mounts, just like native controllers does:

```ruby
app = EApp.new do
  
  # ...
  mount Cms, '/cms', '/pages'  # this will mount Sinatra app into /cms and /pages
end
```

## Run


By default Espresso will use WEBrick server and default WEBrick port.

To use another server, pass `:server` option.

If given server requires some options, pass them next to `:server` option.

**Example:** Use Thin server and its default port

```ruby
app.run :server => :Thin
```

**Example:** Use EventedMongrel server with custom options

```ruby
app.run :server => :EventedMongrel, :Port => 9090, :num_processors => 100
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

app = App.mount
# or
app = EApp.new :automount
# etc .

run app
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
