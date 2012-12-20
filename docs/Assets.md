
Intro
---

Espresso allows you to load and serve assets with easy.

To load a script you simply do:

```ruby
script_tag 'script.js'
```

or via assets loader:

```ruby
js 'script'
```

Same for stylesheets and images:

```ruby
style_tag 'style.css'

img_tag 'image.png'
```

or via assets loader:

```ruby
css 'style'

png 'image'
```

By default assets will be loaded from current folder, that's it, `src`/`href`
will look like `src="script.js"` / `href="style.css"`

To have them mapped to some URL, use assets mapper.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

Mapper
---

`assets_map` is a method of dual meaning:

  - it defines a baseurl for assets loader
  - and it may instruct your app to act as an assets server

As said above, by default assets will be loaded from current folder.

To define a baseurl to load assets from, use `assets_map`(or `assets_url` alias) at app level:


```ruby
class App &lt; E
  map '/'
  ...
end

app = EApp.new do
  
  mount App

  assets_map :assets
end

app.run
```

Now your assets will load from '/assets' baseurl.

Example:

```ruby
script_tag 'script.js'
# or
js 'script'
```

both will return `<script src="/assets/script.js" ...`


Same for stylesheets and images:

```ruby
style_tag 'style.css'
# or
css 'style'
```

both will return `<link href="/assets/style.css" ...`

```ruby
img_tag 'image.png'
# or
png 'image'
```

both will return `<img src="/assets/image.png" ...`

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

Server
---

The second meaning of assets mapper is to instruct your app to act as an assets server, that's it, your app will serve static files.

For this to work simply set second argument of `assets_map` to any positive value:

```ruby
app = EApp.new do
  ...

  assets_map :assets, :assets_server
end
```

Now your app will serve files found under `public/` folder inside app root.

So `<script src="/assets/script.js" ...` will serve `public/script.js`

If your files are located under another folder inside app root, 
use `assets_path` to inform assets server about custom location:

```ruby
app = EApp.new do
  ...

  assets_map :assets, :assets_server

  assets_path :static
end
```

Now your app will serve files found under `static/` folder inside app root.

So `<script src="/assets/script.js" ...` will serve `static/script.js`


If your files are located out of app root, use `assets_fullpath`:

```ruby
app = EApp.new do
  ...

  assets_map :assets, :assets_server

  assets_fullpath '/full/path/to/Shared-assets'
end
```

Now your app will serve files found under `/full/path/to/Shared-assets/` folder.

So `<script src="/assets/script.js" ...` will serve `/full/path/to/Shared-assets/script.js`

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

Helpers
---

For now, Espresso offers 3 helper methods:

  - `script_tag`
  - `style_tag`
  - `img_tag`

All accepts from 1 to 2 arguments.

Usually first argument is the file to be loaded and the second the options to be added to the tag:

```ruby
script_tag 'some-file.js', :async => true, :charset => 'UTF-8'
#=&gt; &lt;script src="some-file.js" async="true" charset="UTF-8" ...
```

You can also omit the first argument and pass file via `:src` option.

This is useful when you need to skip assets mapper setup and load file directly.

Let's suppose assets mapper is set to load files from `/assets` baseurl
but we need to load a script from our CDN:

```ruby
script_tag :src => 'http://some.cdn/script.js'
#=&gt; &lt;script src="http://some.cdn/script.js" ...

# without :src option

script_tag 'script.js'
#=&gt; &lt;script src="/assets/script.js" ...
```

Same for rooted URLs inside your app.

Let's suppose baseurl is set to `/vendor` but we need to load a stylesheet from root:

```ruby
style_tag :src => '/themes/black.css'
#=&gt; &lt;link href="/themes/black.css" ...

# without :src option

style_tag 'bootstrap/bootstrap.css'
#=&gt; &lt;link href="/vendor/bootstrap/bootstrap.css" ...
```

Same when you need to load a file from current folder.

Let's suppose baseurl is set to `/static` but we need to load a image from current folder:

```ruby
img_tag :src => 'banner.png'
#=&gt; &lt;img src="banner.png" ...

# without :src option

img_tag 'banner.png'
#=&gt; &lt;img src="/static/banner.png" ...
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

Loader
---

Assets loader allow to save time and space 
by avoiding repetitive and redundant path typing.

It is like a mapper for a local set of assets.

Let's suppose we need to load N files from `/assets/vendor` 
and another M files from `/assets/app`

Then we set baseurl to `/assets` via `assets_map` and loading files from `vendor/` and `app/`:

```ruby
app = EApp.new
  ...

  assets_map :assets
end

# in templates:

script_tag 'vendor/jquery.js'
script_tag 'vendor/bootstrap/js/bootstrap.js'
style_tag  'vendor/bootstrap/css/bootstrap.css'

script_tag 'vendor/html5-boilerplate/js/main.js'
style_tag  'vendor/html5-boilerplate/css/main.css'

script_tag 'app/js/boot.js'
script_tag 'app/js/setup.js'
script_tag 'app/js/app.js'
style_tag  'app/css/theme.css'
```

This will work well, but it is cumbersome.

Assets loader will let us do the same with much less code:

```ruby
asl = assets_loader :vendor

asl.js 'jquery'

asl.cd  :bootstrap
asl.js  'js/bootstrap'
asl.css 'css/bootstrap'

asl.cd  '../html5-boilerplate'
asl.js  'js/main'
asl.css 'css/main'


asl = assets_loader :app

asl.cd 'js'
asl.js 'boot'
asl.js 'setup'
asl.js 'app'

asl.cd  '../css'
asl.css 'theme'
```

Or even shorter with blocks:

```ruby
assets_loader :vendor do

  js 'jquery'

  cd  :bootstrap
  js  'js/bootstrap'
  css 'css/bootstrap'

  cd  '../html5-boilerplate'
  js  'js/main'
  css 'css/main'
end

assets_loader :app do

  cd 'js'
  js 'boot'
  js 'setup'
  js 'app'

  cd  '../css'
  css 'theme'
end
```

You can also pass multiple files as arguments:

```ruby
assets_loader :app do

  cd 'js'
  js :boot, :setup, :app
end
#=&gt; &lt;script src="/app/js/boot.js" ...
#=&gt; &lt;script src="/app/js/setup.js" ...
#=&gt; &lt;script src="/app/js/app.js" ...
```

Blocks will automatically return a string containing generated tags.

Each tag ending in `\n` character.

If you need tags returned as an array, without `\n` character at the end, send `to_a` to the block:

```ruby
tags = assets_loader :app do

  cd 'js'

  js :boot, :setup, :app
end.to_a

# joining and displaying tags

tags.join("\n  \n")
```


**Worth to note** that assets loader can skip assets mapper setup,
that's it, you can load assets from any location.

This will basically work for locations starting with:
  
  - a protocol: `http://` `https://`  etc.
  - a slash: `/`
  - a dot slash notation: `./` meant to load assets from current folder

**Example:** load assets from `http://my.cdn`, regardless assets mapper setup:

```ruby
assets_loader 'http://my.cdn' do

  js 'jquery'

  cd  :bootstrap
  js  'js/bootstrap'
  css 'css/bootstrap'

  cd  '../html5-boilerplate'
  js  'js/main'
  css 'css/main'
end
```

**Example:** load assets from current folder, regardless assets mapper setup:

```ruby
assets_loader './app' do

  cd 'js'
  js 'boot'
  js 'setup'
  js 'app'

  cd  '../css'
  css 'theme'
end
```

**And that's not all.**

You can skip both assets mapper and assets loader setup if you need.

For this simply pass `:src` option to any of `js`, `css`, `img` methods.

```ruby
app = EApp.new do
  ...

  assets_map '/assets'
end

# in templates:

assets_loader '/vendor' do

  js 'jquery'
  #=&gt; &lt;script src="/assets/vendor/jquery.js" ...

  js :src => '/master'
  #=&gt; &lt;script src="/master.js" ...
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
