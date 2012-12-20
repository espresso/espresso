## Global Setup


The main idea behind actions setup is to easily manipulate the action's behavior
without touching the actions et all.

That's allow to "remotely" control any number of actions with few lines of code
and manipulate their behavior without actions refactoring.

To illustrate an example, let's suppose that all actions should return UTF-8 charset.

```ruby
class App < E

    charset 'UTF-8'

    # ...
end
```

Now you can define any number of actions without bothering to add the charset inside each one.

And when you need your actions to return another charset,
simply change a single line of code at class level.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Setup by Name


Global setup is just good for mostly trivial apps.

But when it comes to develop more compelling apps, we need more control.

And Espresso kindly offer it.

**# 1** - Actions can be configured by name

**Example:** - all actions, but `:api` and `:json`, should return "text/plain" content type.
`:api` and `:json` actions should return  "application/json"

```ruby
class App < E

    content_type '.txt'

    setup :api, :json do
        content_type '.json'
    end

    # ...
end
```

**# 2** - Actions can be configured by name regular expressions

**Example:** - all actions containing "_js_" will return "application/javascript" content type

```ruby
class App < E

    setup /_js_/ do
        content_type '.js'
    end

    # ...
end
```

**Please Note** that when you firstly setup actions by regexp
then try to setup a specific action, the last setup will be ignored.

To override setup set by regexp, use bang methods in specific setups.

**Example:**

```ruby
class App < E

    setup /red/ do
      engine :ERB
    end

    setup :red_pants do
      engine  :Erubis   # :red_pants will still use ERB engine
      engine! :Erubis   # :red_pants will use Erubis engine
    end
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Setup by Format


[Format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format) is a part of routing mechanism
but it is also hugely used when it comes to setup actions.

It turns out that setting up actions by name and regular expressions are not enough.

We need even more control.

Cause "/book.html" and "/book.xml" definitely may behave diferently, even if they are backed by the same action.

How for ex. to tell `book` action to return some charset on "/book.html" URL
and another one on "/book.xml" URL without touching the action itself?

Here is where format comes in action.

**# 1** - To add some setup only for specific format, provide action name as a string, suffixed by desired format.

**Example:** - set charset only for `foo` action only when it is called with `.json` format

```ruby
class App < E
    format :json

    setup 'foo.json' do
        charset 'UTF-8'
    end

    def foo
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
    format :html, :htm

    setup '.html' do
        cache_control :public, :must_revalidate, :max_age => 600
    end

    setup '.htm' do
        cache_control :private, :must_revalidate, :max_age => 60
    end

    # ...
end
```

**Important Note!** When setting up actions by format wildcard,
Espresso will preserve that setup for all actions matching given format.

And when you want to setup a specific action after you did a wildcard setup,
you'll note that specific setup is ignored.

It may look confusing, though it is not,
cause specific action you want to setup already has a setup.

To override an existing setup, simply use bang methods.

**Example:**

```ruby
class App < E

    format :html

    setup '.html' do
      engine :ERB
    end

    setup 'blah.html' do
      engine  :Erubis   # this wont work
      engine! :Erubis   # this will work
    end
end
```

Same for cases when you firstly setup a specific action,
then trying to setup actions by format wildcard.


**Example:**

```ruby
class App < E

    format :html

    setup 'blah.html' do
      engine :ERB
    end

    setup '.html' do
      engine  :Erubis   # :blah action will still use ERB engine
      engine! :Erubis   # :blah action will use Erubis engine
    end
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

run Forum.mount '/forum' do
    charset! 'UTF-8'
end
```

That's it.

*Please note* bang method, it will ensure that initial setup will be overridden.<br/>
There are bang methods for all Espresso setups.


Passing setup proc at mount is not the only way to setup controllers.

You can setup them all at once by using `app#setup` method.

```ruby
class Pages < E
    # ...
end

class News < E
    # ...
end

class Articles < E
    # ...
end

app = EApp.new :automount
app.setup do
    # here setup will run inside all controllers
end
app.run

# or you can setup controllers selectively - controller name are passed as first argument of setup proc

app = EApp.new :automount
app.setup do |ctrl|
    if ctrl == Pages
        # here setup will run ONLY inside Pages controller
    end
    # here setup will run inside all controllers
end
app.run
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
