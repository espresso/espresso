## Base URL


By default, each class will serve the path built from its underscored name.

Ex.: `Forum` will serve "/forum", `LatestNews` will serve "/latest_news" etc.

This can be changed by setting base URL via `map`.

**Example:** - `Book` app should serve "/books"

```ruby
class Book < E
    map '/books'

    def index
        # ...
    end

    def edit
        # ...
    end
end
```

<pre>
Now `Book` will serve:
    /books         - backed by Book#index
    /books/index   - backed by Book#index
    /books/edit    - backed by Book#edit
</pre>


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Canonicals


Lets say you need your `News` app to serve both "/news" and "/headlines" base URLs.<br/>
It is easily done by using `map` with multiple params.<br/>
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

To find out either current URL is a canonical URL use `canonical?`<br/>
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


Defining Espresso actions is as simple as defining Ruby methods,<br/>
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
```

Now `App` will serve:
*   /
*   /index
*   /edit


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Actions Mapping


Usually actions should also contain non-alphanumeric chars.<br/>
Most common - hyphens, dots and slashes.

To address this, Espresso uses a map to translate action names into HTTP paths.

The default map looks like this:

<pre>
"____"    => "."
"___"     => "-"
"__"      => "/"
</pre>

**Example:**

```ruby
def read____html   # 4 underscores
    # ...
end
# will serve read.html

def latest___news  # 3 underscores
    # ...
end
# will serve latest-news

def users__online  # 2 underscores
    # ...
end
# will serve users/online
```

*Worth to note* that you can define your own rules by using `path_rule` at class level.

**Example:** - Convert bang methods into .html suffixed paths

```ruby
class App < E
    map '/'

    path_rule "!", ".html"

    def news!
        # ...
    end
end

# `news!` will serve /news.html
```

**Example:** - Convert methods starting with j_ into .json suffixed paths

```ruby
class App < E
    map '/'

    path_rule /\Aj_/, ".json"

    def j_news
      # ...
    end
end
# `j_news` will serve /news.json
```


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

If we do an request like this - "/read/news/latest", it will be decomposed as follow:

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

In a word, if Ruby method works with given params, HTTP action will work too.<br/>
Otherwise, HTTP action will return "404 NotFound" error.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Format


`format` allow to manipulate routing by instructing actions to respond to various extensions.

**Example:**

```ruby
class App < E
    map '/'
    format :xml

    def article
        # ...
    end
end
```

In the example above, article action will respond to both "/article" and "/article.xml" URLs.

`format` accepts any number of arguments. Each argument is a new extension action(s) will respond to.

The second meaning of `format` is to automatically set Content-Type header.

Content type are extracted from `Rack::Mime::MIME_TYPES` map.<br/>
Ex: `format :txt` will return the content type extracted via `Rack::Mime::MIME_TYPES.fetch('.txt')`

To set format(s) only for some actions, use `setup`.

**Example:** - only `:pages` and `:news` actions will respond to URLs ending in .html and .xml

```ruby
class App < E
    map '/'

    setup :pages, :news do
        format :xml, :html
    end

    def read
        # ...
    end

    def pages
        # ...
    end

    def news
        # ...
    end

    # ...
end
```

Voila, now App will respond to any of "/pages", "/pages.html", "/pages.xml", "/news", "/news.html", "/news.xml",
but not to "/read.html" nor to "/read.xml", cause `format` was set for `pages` and `news` only.


But wait, actions usually are called with params, and an URL like "/read.html/100" looks really bad!

No problem! Espresso takes care about this, and "/read/100.html" will work exactly as "/read.html/100"

Even more! Espresso will get rid of format passed in last param, so you get clean params without remove format manually.<br/>
Meant that when "/news/100.html" requested, you get "100" param inside `news` action, rather than "100.html"

**Example:**

```ruby
class App < E
    format :xml

    def read item = nil
        # on /read             item == nil
        # on /read.xml         item == nil
        # on /read.xml/book    item == "book"
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

**Worth to Note** - if both action and last param has format, action format is used.

**Example:**

```ruby
class App < E
    format :xml, :json

    def read item = nil
        # ...
    end
end
```

<pre>
/read/book.json          will return JSON Content-Type
/read.xml/book.json      will return XML Content-Type instead
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

## Aliases


As we already noted, any app can serve multiple paths.

But what if we need an action to be available by multiple paths?

It's easy - add an standard Ruby alias.

**Example:**

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


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Rewriter


Espresso uses a really flexible rewrite engine,
which allows to redirect the browser to new address
as well as pass control to arbitrary app(without redirect)
or just send response to browser(without redirect as well).

A rewrite rule consist of regular expression and a block that receives matches as params.

`redirect` and `permanent_redirect` will redirect browser to new address with 302 and 301 codes respectivelly.

**Example:**

```ruby
class App < E

    rewrite /\A\/(.*)\.php\Z/ do |title|
        redirect route(:index, title)
    end

    # ...
end
```

`pass` will pass control to an arbitrary action or even app, without redirect.

**Example:**

```ruby
class Articles < E

    def read title
        # ...
    end
end

class Pages < E

    # pass old pages to archive action
    rewrite /\A\/(.*)\.php\Z/ do |title|
        pass :archive, title
    end

    # pages ending in html are actually articles, so passing control to Articles app
    rewrite /\A\/(.*)\.html\Z/ do |title|
        pass Articles, :read, title
    end

end

```

`halt` will send response to browser and stop any code execution, without redirect.

It accepts from 0 to 3 arguments.<br/>
If argument is a hash, it is added to headers.<br/>
If argument is a Integer, it is treated as Status-Code.<br/>
Any other arguments are treated as body.

If a single argument given and it is an Array, it is treated as a bare Rack response and instantly sent to browser.

**Example:**

```ruby
class App < E

    rewrite /\A\/archived\/(.*)\.html\Z/ do |title|

        page = Model::Page.first(:url => title) || halt(404, 'page not found')

        halt page.content, 'Last-Modified' => page.last_modified.to_rfc2822
    end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
