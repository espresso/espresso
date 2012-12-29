## Global Setup


The main idea behind actions setup is to easily manipulate the action's behavior
without touching the actions at all.

That's allow to "remotely" control any number of actions with just few lines of code
and manipulate their behavior without actions refactoring.

To illustrate an example, let's suppose that all actions should return UTF-8 charset.

```ruby
class App < E

  charset 'UTF-8'

  # ...
end
```

Now you can define any number of actions without bothering to add the charset inside each one.

And when you need to change the charset returned by your actions
simply change a single line of code at class level.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Setup by Name


Global setup is just good for mostly trivial apps.

But when it comes to develop more compelling apps, we need more control.

And Espresso kindly offer it.

**# 1** - Actions can be configured by name

**Example:** - all actions, but `:api` and `:json`, should return "text/plain" content type.
`:api` and `:json` instead should return  "application/json"

```ruby
class App < E

  content_type '.txt'

  setup :api, :json do
    content_type '.json'
  end

  # ...
end
```

**# 2** - Actions can be configured via regular expressions

**Example:** - all actions containing "_js_" will return "application/javascript" content type

```ruby
class App < E

  setup /_js_/ do
      content_type '.js'
  end

  # ...
end
```


## Setup by Format


[Format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format) is a part of routing mechanism
but it is also hugely used when it comes to setup actions.

It turns out that setting up actions by name and regular expressions are not enough.

We need even more control.

Cause "/book.html" and "/book.xml" definitely may behave differently, even if they are backed by the same action.

How for ex. to tell `book` action to return some charset on "/book.html" URL
and another one on "/book.xml" URL without touching the action itself?

Here is where format comes in action.

**# 1** - To add some setup only for specific format, provide action name as a string, suffixed by desired format.

**Example:** - make /book.xml to use `Nokogiri` engine and /book.html `Slim` engine

```ruby
class App < E
  format '.xml', '.html'

  setup 'book.xml' do
    engine :Nokogiri
  end
  setup 'book.html' do
    engine :Slim
  end

  # or
  setup :book do
    engine :Nokogiri if xml?
    engine :Slim     if html?
  end

  def book
    # ...
  end
end
```

That's great, but useless when we have N actions to setup, cause we will have to define a setup for each action.

That's weird.

And here is where the format comes in action for the second time.

**# 2** - To setup all actions that respond to some format, simply provide format without action name.

**Example:** - use different Cache-Control header for different formats

```ruby
class App < E
  format '.html', '.xml'

  setup '.html' do
    cache_control :public, :must_revalidate, :max_age => 600
  end

  setup '.xml' do
      cache_control :private, :must_revalidate, :max_age => 60
  end

  # ...
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Remote Setup


Any Espresso controller or slice can be packed as a gem and then installed on any server.<br/>
Very useful when you need distributed apps.

And it becomes even more useful with Remote Setup.

Say you need the same app to run some setup on Server A and another setup on Server B,
without touching/refactor the app at all.

Easy!

Let's say we have a Forum app that serves /Forums base URL and returns content of ISO-8859-1 charset.

That's ok for Server A.

But for Server B we need it to serve /forum base URL and return UTF-8 charset.

For this, we pass the base URL as first param and setting charset using bang method inside block.

**Example:** - deploying Forum app on Server B

```ruby
require 'my-mega-forum'

run Forum.mount '/forum' {
  charset 'UTF-8'
}
```

That's it.

However, passing setup proc at mount is not the only way to setup controllers.

You can setup them all at once by using `app#global_setup` method.

```ruby
module App
  class Pages < E
    # ...
  end

  class News < E
    # ...
  end

  class Articles < E
    # ...
  end
end

app = EApp.new
app.global_setup do
  # here setup will run inside all controllers
end
app.mount App
app.run
```

Or you can setup controllers selectively - controller name are passed as first argument of setup proc

```ruby
app = EApp.new
app.setup do |ctrl|
  if ctrl == App::Pages
    # here setup will run ONLY inside Pages controller
  end
  # here setup will run inside all controllers
end
app.mount App
app.run
```

Please note that **#mount should always go after #global_setup**,
otherwise global setup will have no effect.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

