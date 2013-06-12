
## Route


Use `route` at class or instance level to get the URL of given action.

Returned URL will consist of controller's base URL and the action's path.

If controller does not respond to given action, it will simply use it as part of URL.

If called without arguments it will return controller's base URL.

**Example:**

```ruby
class App < E
  map '/books'

  def read
    # ...
  end

  def test
    route :read #=> /books/read
  end
end

App.route #=> /

App.route :read  #=> /books/read

App.route :blah  #=> /books/blah
```

**Worth to note** that `route` are RESTful friendly,
meant you can pass action name without REST verb:

```ruby
class App < E
  map '/'

  def post_edit
    route(:post_edit)   #=> /edit
    route(:edit)        #=> /edit
  end

  def put_edit
    route(:put_edit)    #=> /edit
    route(:edit)        #=> /edit
  end
end

App.route(:post_edit)   #=> /edit
App.route(:edit)        #=> /edit
  
App.route(:put_edit)    #=> /edit
App.route(:edit)        #=> /edit
```


If any params given(beside action name) they will become a part of generated URL.

**Example:**

```ruby
class News < E

  def index
    route :latest___items, 100 #=> /news/latest-items/100
  end

  def latest___items ipp = 10, order = 'asc'
    # ...
  end
end

News.route #=> /news

News.route :latest___items #=> /news/latest-items

News.route :latest___items, 20, :desc #=> /news/latest-items/20/desc
```

If a Hash given, it will be passed as query string.

**Example:**

```ruby
route :read, :var => 'val' #=> /read?var=val

# nested params
route :view, :var => ['1', '2', '3'] #=> /view?var[]=1&var[]=2&var[]=3

route :open, :vars => {:var1 => '1', :var2 => '2'}
#=> /open?vars[var1]=1&vars[var2]=2
```

To get action route along with format, pass the action name as string, having desired format as suffix.<br>
If action does not support given format, it will simply be used as a part of URL.

**Example:**

```ruby
class Rss < E
  map :reader
  format :html, :xml

  def mini___news
    # ...
  end
end

Rss.route :mini___news
#=> /reader/mini-news

Rss.route 'mini___news.html'
#=> /reader/mini-news.html

Rss.route 'mini___news.xml'
#=> /reader/mini-news.xml

Rss.route 'mini___news.json'
#=> /reader/mini___news.json
```

You can also append format to last param and all the setups set at class level will be respected,
just as if format passed along with action name.

**Please note** that though last param given with format,
inside action it will be passed without format,
so you do not need to remove format manually.

**Example:**

```ruby
class App < E
  map '/'
  format :html

  def read item = nil
    # on /read              item == nil
    # on /read/news         item == "news"
    # on /read/book.html    item == "book", not "book.html"
    # on /read/100.html     item == "100", not "100.html"
    # on /read/blah.xml     item == "blah.xml", cause ".xml" format not served
  end
end

App.route :read, 'book.html'
#=> /read/book.html

App.route :read, '100.html'
#=> /read/100.html

App.route :read, 'etc.html'
#=> /read/etc.html

App.route :read, 'blah.xml'
#=> /read/blah.xml
```

If you need **just the action route, without any params**, use `[]` at class or instance level.

Will return `nil` if given action not found or does not support the given format.

**Example:**

```ruby
class Index < E
  map :cms
  format :html

  def read
  end

  def quick___reader
  end

  def test
    self[:read]
    #=> /cms/read

    self[:quick___reader]
    #=> /cms/quick-reader

    self['quick___reader.html']
    #=> /cms/quick-reader.html

    self['quick___reader.json']
    #=> nil

    self[:blah]
    #=> nil
  end
end

Index[:read]
#=> /cms/read

Index[:quick___reader]
#=> /cms/quick-reader

Index['quick___reader.html']
#=> /cms/quick-reader.html

Index['quick___reader.json']
#=> nil

Index[:blah]
#=> nil
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Params


`params` - a mix of GET and POST params. Can be accessed by both symbol and string keys.

**Example:**

```ruby
class App < E
  map '/'

  def test
    # on /test?foo=bar  params[:foo] == "bar"
    # ...
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Passing Control

Espresso allow to stop execution of current context and pass control to next matching action:

```ruby
class Reader < E
  def index(*)
    render # display a list of books to choose from
  end

  def read book
    pass unless books_in_account.include?(book) # will go to :index action
    render # read the book
  end
end
```

`env['espresso.gateways']` will display the list of tried routes before matched one.

It is also possible to pass control to a given action or controller:

**Important:** If no params given, actual params will be passed.

**Example:** - Pass control to :archived action if page id is less than 100_000

```ruby
class App < E

  def index id
    id = id.to_i
    pass :archived if id < 100_000
    #
    # code here will be executed only when id > 100_000
    #
  end
end
```


**Example:** - Pass control to :json action if browser accepts JSON.
If some params given, they will be passed as arguments to destination action.

```ruby
class App < E

  def index
    pass(:json, params[:type], params[:id]) if accept?(/json/)
    # ...
  end

end
```

**Example:** - Passing control with modified arguments and custom HTTP params.

```ruby
def index
  pass :some_action, :some_arg, :foo => :bar
end
```

If first argument is a valid Espresso controller, the control will be passed to it.

**Example:** - Passing control to inner app

```ruby
class News < E

  def index id, page = 1
    # ...
  end
end

class Index < E
  map '/'

  def index
    pass News, :index if params[:type] == 'news'
    # ...
  end
end
```

By default, a GET request will be issued.

To use another request method, append it to the used method.

**Example:**

```ruby
pass_via_post :some_action
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Fetching Body


Sometimes you need to invoke some action(on same or inner controller) and get the returned body.

This is easily done by using `fetch`.

`fetch` will invoke some action(via HTTP) inside current or given controller and returning the body.

Basically, this is same as `pass` except it returns the body instead of halting request processing.

Another **important** difference is that `fetch` will not pass actual HTTP params.

**Example:**

```ruby
class Store < E

  def products
    @latest_blog_posts = fetch(Blog, :latest)
    # ...
  end

  def featured_products
    # ...
  end
end

class Blog < E

  def index
    @featured_products = fetch(Store, :featured_products)
    # ...
  end
end
```

If you need status code and/or headers, use `invoke` instead, which will return a Rack response Array.

It is also possible to use a request method other than default GET.

**Example:**

```ruby
fetch_via_post :some_action

invoke_via_put :some_action
# etc.
```

Also an XHR request can be mimed:

```ruby
xhr_fetch :some_action

xhr_invoke :some_action
# etc.
```

And of course XHR requests can be issued via any request method:

```ruby
xhr_fetch_via_post :some_action

xhr_invoke_via_delete :some_action
# etc.
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Halt


`halt` will interrupt any process and send an arbitrary response to browser.

It accepts from 0 to 3 arguments.<br>
If argument is a hash, it is added to headers.<br>
If argument is a Integer, it is treated as Status-Code.<br>
Any other arguments are treated as body.

If a single argument given and it is an Array, it is treated as a bare Rack response and instantly sent to browser.

**Example:**

```ruby
def index
  halt 'Hit the Road Jack' if SomeHelper.malicious_params?(env)
  # ...
end
```

**Example:** - Status code

```ruby
def index
  begin
    # some logic
  rescue => e
    halt 500, exception_to_human_error(e)
  end
end
```

**Example:** - Custom headers

```ruby
def news
  if params['return-rss']
    halt rssify(@items), 'Content-Type' => mime_type('.rss')
  end
end
```

**Example:** - Rack response

```ruby
def download
  halt [200, {'Content-Disposition' => "attachment; filename=some-file"}, some_IO_instance]
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Redirect


`redirect` will interrupt any process and redirect browser to new address with status code 302.

To redirect with status code 301 use `permanent_redirect`.

To wait until request processed, use `delayed_redirect` or `deferred_redirect`.

If an existing action passed as first argument, it will use the route of given action for location.

If first argument is a valid Espresso controller, it will used setup to build the path.

**Example:** - Basic redirect with hardcoded location(bad practice in most cases)

```ruby
redirect '/some/path'
```

**Example:** - Basic redirect with dynamic location

```ruby
class Articles < E

  def index
    redirect route         # => /articles
    redirect :read, 100      # => /articles/read/100
    redirect News          # => /news
    redirect News, :read, 100    # => /news/read/100
  end

  def read id
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Reload


`reload`  will simply refresh the page.

**Example:** - Refreshing with same GET params

```ruby
def index
  # ...
  reload
end
```

**Example:** - Refreshing with custom GET params

```ruby
def index
  # ...
  reload :some => 'param', :some_another => 'param'
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Error Handlers


Espresso allow to set error handlers that can be used to throw errors with desired status code and body.

When setting error handler, you should provide status code and a proc that will generate the body.<br>
The proc may accept an argument. That will be the error message.

When using handler, the only required argument is status code.<br>
If error message given as 2nd argument, it will be passed to the error handler proc as first argument.

**Example:** - Setting and using 404 error handler

```ruby
class News < E

  error 404 do |message|
    "Some Error Occurred: #{ message }"
  end

  def index id
    @page = PageModel.first(:id => id)
    @page || error(404, "Page Not Found, sad...")
         # will return 404 status code with body
         # "Some Error Occurred: Page Not Found, sad..."
    # ...
  end
end
```

**Example:** - Setting and using 500 error handler

```ruby
class News < E

  error 500 do |exception|
    "Fatal Error Occurred: #{ exception }"
  end
  # now if yous actions(or hooks) raise an exception,
  # it will be rescued and passed to your error handler.

  def index id
    some risky code here
  end
  # will return 500 status code with body
  # "Fatal Error Occurred: undefined local variable or method `here'"
end
```

**Example:** Using handler without passing an error message

```ruby
class App < E

  error 404 do
    "Ouch... something weird happened or you just visited a wrong URL..."
  end

  def page id
    error(404) unless @page = PageModel.first(:id => id)
    # ...
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Hooks


`before` and `after` allow to set callbacks to be called before and after action processed.

`around` allow to define a block that will wrap execution of current action. Just type your stuff and call `invoke_action` where you need action to be executed.


**Example:**

```ruby
class App < E

  before do
    @started_at = Time.now.to_f
  end

  after do
    puts " - #{ action } consumed #{ Time.now.to_f - @started_at } milliseconds"
  end

  # ...
end
```

**Example:** graciously throw an error if some /remote/ action takes more than 5 seconds to run

```ruby
class App < E

  around /remote/ do
    Timeout.timeout(5) do
      begin
        invoke_action # executing action
      rescue => e
        fail 500, e.message
      end
    end
  end

  def remote_init
    # occasionally slow action
  end

  def remote_post
    # occasionally slow action
  end

  def remote_fetch
    # occasionally slow action
  end
end
```

To set callbacks only for specific actions, use actions names as arguments(matchers).

**Example:** - Extract item from db only before :edit, :update and :delete actions

```ruby
class App < E

  before :edit, :update, :delete do
    @item = Model.first(:id => action_params[:id].to_i)
  end

  def edit id
    # ...
  end

  def update id
    # ...
  end

  def delete id
    # ...
  end
end
```

Also regular expressions can be used as arguments(matchers).

**Example:** - any action containing "_js_" in its name will respond with "application/javascript" Content-Type

```ruby
before /_js_/ do
  content_type '.js'
end
```

**Please Note** that `before` is just an alias for `setup`.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Authorization


Types supported:

*   Basic
*   Digest
*   Token

### Basic Authorization

**Example:** - All actions under Admin controller will require Basic authorization

```ruby
class Admin < E

  auth do |user, pass|
    [user, pass] == ['admin', 'somePasswd']
  end
end
```

**Example:** - Only :my_bikini_photos action will require(Basic) authorization

```ruby
class MyBlog < E

  setup :my_bikini_photos do
    auth :my_bikini_photos do |user, pass|
      user == "admin" && pass == "super-secret-password"
    end
  end

  def my_bikini_photos
    # HTML containing top secret photos
  end
end
```

### Digest Authorization

**Example:** - Everything under Admin slice will require(Digest) authorization

```ruby
module Admin
  class Products < E
    # ...
  end
  class Orders < E
    # ...
  end
end

app = Admin.mount do
  digest_auth do |user|
    users = { 'admin' => 'password' }
    users[user]
  end
end
app.run
```

### Token based Authorization

```ruby
class App < E
  TOKEN = "secret".freeze

  before :edit do
    token_auth { |token| token == TOKEN }
  end

  def index
    "Everyone can see me!"
  end

  def edit
    "I'm only accessible if you know the password"
  end
end
```

**Example:**  more advanced Token example where only Atom feeds and the XML API is protected by HTTP token authentication

```ruby
class App < E
  before :set_account do
    authenticate
  end

  def set_account
    @account = Account.find_by ...
  end

  private
  def authenticate
    if accept? /xml|atom/
      if user = valid_token_auth? { |t, o| @account.users.authenticate(t, o) }
        @current_user = user
      else
        request_token_auth!
      end
    else
      # session based authentication
    end
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Sessions


In order sessions to work they have to be enabled first.

Sessions are enabled at app level and by default can be stored in memory, cookies or memcache.

You can of course use any Rack session adapter, for example `rack-session-mongo`.

**Example:** - Keeping sessions in memory

```ruby
class App < E
  # ...
end
app = App.mount
app.session :memory
app.run
```

**Example:** - Keeping sessions in cookies

```ruby
class App < E
  # ...
end
app = App.mount
app.session :cookies
app.run
```

**Example:** - Keeping sessions in memcache

```ruby
class App < E
  # ...
end
app = App.mount
app.session :memcache
# or
app.use Rack::Session::Memcache, :with, :some => :args
app.run
```

**Example:** - Keeping sessions in mongodb

```bash
$ gem install rack-session-mongo
```

```ruby
class App < E
  # ...
end

require 'rack/session/mongo'

app = App.mount
app.session Rack::Session::Mongo, :with, :maybe, :some => :args
app.run
```

**Read/Write Sessions**

```ruby
session['session-name'] = 'value'

session['session-name']
#=> value
```

**Deleting**

```ruby
session.delete 'session-name'
```


## Flash


Burn after reading! :)

`flash` allow to store a message that will be purged after first read.<br>
The message are stored in sessions and are consistent between requests.

**Example:**

```ruby
# setting  message
flash[:message] = 'top secret info'

# read message
flash[:message]
#=> top secret info

# message automatically purged after reading
flash[:message]
#=> nil
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Cookies


**Example:** - Setting a cookie

```ruby
cookies['cookie-name'] = 'value'
```

**Example:** - Reading a cookie

```ruby
cookies['cookie-name']
#=> value
```

**Example:** - Setting a cookie with custom options

```ruby
cookies['question_of_the_day'] = {value: 'who is not who?', expires: Time.now + 86400, secure: true}
```

**Example:** - Deleting a cookie

```ruby
cookies.delete 'cookie-name'
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Content Type

**Example:** - Setting RSS content type at class level, for all actions

```ruby
class Rss < E

  content_type '.rss'

  # ...
end
```

**Example:** - Setting RSS content type only for :feed and :read actions

```ruby
class Rss < E

  setup :feed, :read do
    content_type '.rss'
  end
end
```

**Example:** Setting content type inside action

```ruby
class App < E

  def users
    content_type('.json') if accept?(/json/)
    # ...
  end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Charset


Updating `Content-Type` header by adding specified charset.

Can be set exactly as Content-Type, at class and/or instance level.

**Important:** - `charset` will update only the header,
so make sure that returned body is of same charset as header, if that needed at all.


```ruby
class App < E
  charset 'UTF-8'

  setup /_jp\Z/ do  # setting JIS charset for actions ending in _jp
    charset 'Shift_JIS-2004'
  end

  # ...
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Cache Control


Control content freshness by setting Cache-Control header.

It accepts any number of params in form of directives and/or values.

Can be set at class and/or instance level.

Directives:

*   :public
*   :private
*   :no_cache
*   :no_store
*   :must_revalidate
*   :proxy_revalidate

Values:

*   :max_age
*   :min_stale
*   :s_max_age


**Example:** Setting Cache-Control header at class level

```ruby
class App < E
  cache_control :private, :max_age => 60

  # ...
end
```

**Example:** Setting Cache-Control header at instance level

```ruby
def some_action

  cache_control :public, :must_revalidate, :max_age => 60
  # Cache-Control header will be set to
  # Cache-Control: public, must-revalidate, max-age=60

  # ...
end

def another_action

  cache_control :public, :must_revalidate, :proxy_revalidate, :max_age => 500
  # Cache-Control header will be set to 
  # Cache-Control: public, must-revalidate, proxy-revalidate, max-age=500

  # ...
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Expires


Set `Expires` header and update `Cache-Control` by adding directives and setting max-age value.

First argument is the value to be added to max-age value.

It can be an integer number of seconds in the future or a Time object indicating
when the response should be considered "stale".

Other params are passed to `cache_control!` instance method.

Can be set at class and/or instance level.

**Example:**

```ruby
def some_action
  expires 500, :public, :must_revalidate
  # Cache-Control: public, must-revalidate, max-age=500
  # Expires: Tue, 17 Jul 2012 11:26:58 GMT
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Last Modified


Set the "Last-Modified" header indicating last modified time of the resource.

Then, if the current request includes an "If-Modified-Since" header that is bigger or equal,
the processing will be halted with an "304 Not Modified" response.

Also, if the current request includes an "If-Unmodified-Since" header that is less than "Last-Modified",
the processing will be halted with an "412 Precondition Failed" response.


**Example:**

```ruby
def some_action
  last_modified Time.now - 600
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Accepted Content Type


Usually the browser informs the app about accepted content type via `HTTP_ACCEPT` header.

`accept?` is a helper allowing to disclose what content type are actually accepted/expected by the browser.

It accepts a string or a regular expression as first argument and will compare it to `HTTP_ACCEPT` header.

If you make a request via XHR, aka Ajax, and request JSON content type,
`accept?` will return a string containing "application/json".

Having this, it is easy to determine what content type to send back.

**Example:**

```ruby
class App < E

  def some_action
    if accept? /json/
      content_type '.json'
    end
  end
end
```

Other browser expectations:

*  accept_charset?
*  accept_encoding?
*  accept_language?
*  accept_ranges?

**Example:**

```ruby
accept_charset? 'UTF-8'
accept_charset? /iso/

accept_encoding? 'gzip'
accept_encoding? /zip/

accept_language? 'en-gb'
accept_language? /en\-(gb|us)/

accept_ranges? 'bytes'
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**



## Send File



`send_file` will send file content to browser, inline.

The only required argument is the full path to file.

**Example:**

```ruby
def theme____css
  send_file File.expand_path('../../public/theme.css', __FILE__)
end
```

All files properties are detected automatically,
however you can modify them by passing an hash of below options:

*   :content_type
*   :last_modified
*   :cache_control
*   :filename

**Example:**

```ruby
send_file '/path/to/file', :cache_control => 'max-age=3600, public, must-revalidate'
```

Recommended to use only with small files.<br>
Or setup your web server to make use of X-Sendfile and use `Rack::Sendfile`.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Send Files


`send_files` allow to serve all files from a given directory.

**Example:**

```ruby
send_files '/path/to/dir'
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Attachment


`attachment` works as `send_file` except it will instruct browser to display "Save" dialog.

**Example:**

```ruby
attachment '/path/to/file'
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Headers


`response.headers`, or just `response[]`, allow to read/set headers to be sent to browser.

**Example:**

```ruby
response['Max-Forwards']
#=> nil

response['Max-Forwards'] = 5

response['Max-Forwards']
#=> 5

# browser will receive Max-Forwards=5 header
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Helpers

To share some helper methods between controllers simply put shared methods into a module and `include` that module into controllers.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
