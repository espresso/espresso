
## Base URL

By default, each class will serve the path built from its underscored name.

Ex.: `Forum` will serve "/forum", `LatestNews` will serve "/latest_news" etc.

This can be changed by setting base URL via `map`.

**Example:** - `Book` app should serve "/books"

```ruby
class Book < E
  map '/books'

  # ...
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Canonicals


Lets say you need your `News` app to serve both "/news" and "/headlines" base URLs.<br>
It is easily done by using `map` with multiple params.<br>
First param will be treated as base URL, any other consequent params - as canonical ones.

**Example:** - `News` should serve both "/news" and "/headlines" paths.

```ruby
class News < E
  map :news, :headlines

  def index
    # ...
  end
end
```

To find out either current URL is a canonical URL use `canonical?`<br>
It will return `nil` for base URLs and a string for canonial ones.

**Example:**

```ruby
class App < E
  map '/', '/cms'

  def page

    # on /page         canonical? == nil
    # on /cms/page     canonical? == "/page"
  end

  # ...
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Actions


Defining Espresso actions is as simple as defining Ruby methods,<br>
cause Espresso actions actually are pure Ruby methods.

**Example:** - Defining 2 actions - :index and :edit

```ruby
class App < E
  map '/'

  def index
    # ...
  end

  def edit
    # ...
  end
end

# Now `App` will now serve:
#  -   /      # backed by `:index` action
#  -   /edit  # backed by `:edit`  action
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Action Mapping


Usually actions should also contain non-alphanumeric chars.<br>
Most common - hyphens, dots and slashes.

To address this, Espresso uses a map to translate action names into HTTP paths.

The default map looks like this:

<pre>
"__"    => "/"
"___"   => "-"
"____"  => "."
</pre>

**Example:**

```ruby
def users__online  # 2 underscores
  # ...
end
# will serve users/online

def latest___news  # 3 underscores
  # ...
end
# will serve latest-news

def read____html   # 4 underscores
  # ...
end
# will serve read.html
```

You can **define your own rules** by using `path_rule` at class level.

**Example:** - Convert bang methods into .html suffixed paths

```ruby
class App < E
  map '/'

  path_rule "!", ".html"

  def news!
    # ...
  end
end

# :news! action will serve /news.html path
```

**Example:** - Convert methods ending in "_j" into .json suffixed paths

```ruby
class App < E
  map '/'

  path_rule /_j$/, ".json"

  def j_news
    # ...
  end
end
# :news_j action will serve /news.json path
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Action Aliases


Though path rules are useful enough, you can bypass them and set routes directly.

**Example:** make `bar` method to serve `/bar`, `/some/url` and `/some/another/url`

```ruby
def bar
  # ...
end

action_alias 'some/url', :bar
action_alias 'some/another/url', :bar
```

**Example:** make `foo` method to serve `/foo` and `/some/url` via any request method

```ruby
def foo
  # ...
end
action_alias 'some/url', :foo
```

**Example:** `get_foo` method will serve `/foo` and `/some/url` only via `GET` request method 

```ruby
def get_foo
  # ...
end
action_alias 'some/url', :get_foo
```

Also standard Ruby `alias` can be used:


```ruby
class App < E
  map '/'

  def news
      # ...
  end
  alias news____html news
  alias headlines__recent____html news
end
```

Now `news` action will serve any of:

*   /news
*   /news.html
*   /headlines/recent.html

**NOTE:** Private and protected methods usually are not publicly available via HTTP.<br>
However, if you add an action alias to such a method, **it becomes public**.<br>
To alias a private/protected method and keep it private,<br>
use  a  standard ruby alias rather than an action alias.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Parametrization


Espresso will split URL by slashes and feed obtained array to the Ruby method that backing current action.

Let's suppose we have an action like this:

```ruby
class App < E
  map '/'

  def read type, status
    # ...
  end
end
```

If we do a request like this - "/read/news/latest", it will be decomposed as follow:

*   action - read
*   params - news/latest

Now Espresso will split params and call action:

```ruby
read "news", "latest"
```

Current example will work just well, cause `read` receives as many arguments as expected.

Now let's suppose we do an request like: "/read/news"

This wont work, cause `read` receives 1 argument instead of 2 expected.

```ruby
read "news"
```

And "/read/news/articles/latest" wont work either, cause `read` receives too many arguments.

```ruby
read "news", "articles", "latest"
```

However, as we know, Ruby is powerful enough.

And Espresso uses this power in full.

So, when we need `read` method to accept 1 or 2 args,
we simply give the last param a default value:

```ruby
class App < E
  map '/'

  def read type, status = 'latest'
    # ...
  end
end
```

Now `read` action will serve "/read/news" as well as
"/read/news/latest", "/read/news/archived", "/read/news/anything!"

Also we can make "/read/news/articles/latest" to work.

```ruby
class App < E
    map '/'

    def read *types, status
        # ...
    end
end
```

That's it! Now when calling "/read/news/articles/latest",
`types` will be an array like ["news", "articles"] and  status will be equal to "latest".

In a word, if Ruby method works with given params, HTTP action will work too.<br>
Otherwise, HTTP action will return "404 NotFound" error.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Format


`format` allow to manipulate routing by instructing actions to respond to various extensions.

Also it is aimed to automatically set `Content-Type` header based on used extension.

**Example:**

```ruby
class App < E
  map '/'
  format '.xml'

  def article
    # ...
  end
end
```

In the example above, article action will respond to both "/article" and "/article.xml" URLs.

`format` accepts any number of extensions.

The second meaning of `format` is to automatically set Content-Type header.

Content type are extracted from `Rack::Mime::MIME_TYPES` map.<br>
Ex: `format '.txt'` will return the content type extracted via `Rack::Mime::MIME_TYPES.fetch('.txt')`

**Worth to note** that `format` will act on all actions.

To set format(s) only for specific actions, use `format_for`.

**Example:** - only `pages` action will respond to URLs ending in .html and .xml

```ruby
class App < E
  map '/'

  format_for :pages, '.xml', '.html'

  def pages
    # ...
  end

  def news
    # ...
  end

  # ...
end
```

Voila, now App will respond to any of "/pages", "/pages.html" and "/pages.xml"<br>
but not "/news.html" nor "/news.xml", cause `format` was set for `pages` action only.

It is also possible to disable format for specific actions by using `disable_format_for`:

```ruby
class App < E
  map '/'

  format '.xml' # this will enable .xml format for all actions
  
  disable_format_for :news, :pages # disabling format for :pages and :news actions

  # ...
end
```

**Worth to note** that Espresso will get rid of extension passed with last param,
so you get clean params without manually remove format.<br>
Meant that when "/news/100.html" requested, you get "100" param inside `news` action, rather than "100.html"

**Example:**

```ruby
class App < E
  format '.xml'

  def read item = nil
    # on /read             item == nil
    # on /read.xml         item == nil
    # on /read.xml/book    404 NotFound
    # on /read/book        item == "book"
    # on /read/book.xml    item == "book"
    # on /read/100.xml     item == "100"
    # on /read/blah.xml    item == "blah"
    # on /read/blah.json   item == "blah.json"
  end
end
```

</pre>
/read.xml                will return XML Content-Type
/read/book.xml           will return XML Content-Type too
/read/100.xml            will return XML Content-Type as well
/read/anything-here.xml  will return XML Content-Type either
/read                    instead will return default Content-Type
/read/book               will return default Content-Type too
</pre>


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## RESTful Actions


By default, verbless actions will respond to any request method.

**Example:** - `index` action responding to any request method

```ruby
class App < E

  def index
  end
end
```

To make an action to respond only to a specific request method,
simply prepend desired request method verb to action name.

**Example:**

```ruby
class App < E

  def post_news  # will serve POST /news
    # ...
  end

  def put_news   # will serve PUT /news
    # ...
  end

  # etc.
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Rewriter


Espresso uses a really flexible rewrite engine,
which allows to redirect the browser to new address
as well as pass control to arbitrary controller(without redirect)
or just send a custom response to browser(without redirect as well).

A rewrite rule consist of a regular expression and a block that receives matches as params.

`redirect` and `permanent_redirect` will redirect browser to new address with 302 and 301 codes respectively.


**Example:**

```ruby
app = EApp.new do

  rewrite /\A\/(.*)\.php\Z/ do |title|
    redirect Cms.route(:index, title)
  end

  # ...
end
```

`pass` will pass control to an arbitrary controller, without redirect.

**Example:**

```ruby
class Articles < E

  def read title
    # ...
  end
end

class Pages < E
  
  def archive title
    # ...
  end
end

app = EApp.new do

  # pass old pages to archive action
  rewrite /\A\/(.*)\.php\Z/ do |title|
    pass Pages, :archive, title
  end

  # pages ending in html are in fact articles, so passing control to Articles controller
  rewrite /\A\/(.*)\.html\Z/ do |title|
    pass Articles, :read, title
  end

end
```

`halt` will send response to browser and stop any code execution, without redirect.

It accepts from 0 to 3 arguments.<br>
If argument is a hash, it is added to headers.<br>
If argument is a Integer, it is treated as Status-Code.<br>
Any other arguments are treated as body.

If a single argument given and it is an Array, it is treated as a bare Rack response and instantly sent to browser.

**Example:**

```ruby
app = EApp.new do

  rewrite /\A\/archived\/(.*)\.html\Z/ do |title|

    unless page = Model::Page.first(:url => title)
      halt 404, 'page not found'
    end

    halt page.content, 'Last-Modified' => page.last_modified.to_rfc2822
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
