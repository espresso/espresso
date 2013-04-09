
Starting with version 0.4, Espresso is using Sprockets to serve assets.

To enable and use this feature, simply call `assets_url` at app level:

```ruby
app = E.new
app.assets_url '/assets'
app.assets.append_path 'assets'
app.run
```

**Note:** make sure you have Sprockets installed. Espresso will require and load it automatically.

**Note:** Espresso will NOT add any path to Sprockets environment, so it is up to you to do this by using `assets.append_path` or `assets.prepend_path`.

**Note:** Sprockets environment will use app root(set via `root` at app level)
as base path, so folders containing assets should reside in your app root.

```ruby
app = E.new do
  assets_url '/assets'
  assets.append_path 'assets'
  assets.append_path 'public'
end
app.run
```

`assets` method can be used to fully setup Sprockets environment:

```ruby
app = E.new do
  assets_url '/assets'
  assets.compile = true
  assets.compress = false
  assets.js_compressor = :uglifier
  # etc.
end

app.run
```

To access assets inside controllers/templates, use `assets` method:

```ruby
class App < E
  # ...

  def some_action
    assets['application.js'] #=> #&lt;Sprockets::BundledAsset ...&gt;
  end

end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


Tag Helpers
---

Espresso offers some useful helpers aimed to easily create HTML tags:

```ruby
js_tag :application
#=> &lt;script src="/assets/application.js" ...

css_tag :application
#=> &lt;link href="/assets/application.css" ...
```

Also helpers for images provided:

    - jpg_tag
    - jpeg_tag
    - png_tag
    - gif_tag
    - tif_tag
    - tiff_tag
    - bmp_tag
    - svg_tag
    - ico_tag
    - xpm_tag
    - icon_tag


Tag helpers will use assets URL as prefix:

```ruby
# --- app.rb ---
class App < E
  # ...

  def index
    render
  end
end

app = E.new do
  assets_url '/public'
end
app.run

# --- view/index.erb ---

js_tag :ui
# =&gt; &lt;script src="/public/ui.js" ...

png_tag 'images/header'
# =&gt; &lt;img src="/public/images/header.png"
```

If you need to load some asset directly, without assets URL prefix, use `:src` option:

```ruby
js_tag :src =&gt; "/jquery"
# =&gt; &lt;script src="/jquery.js" ...

css_tag :src =&gt; "http://my.cdn/theme"
#=> &lt;link href="http://my.cdn/theme.css" ...
```


**Worth to note** that assets mapping can be used without assets being served by Sprockets.

So, when you need to map assets to some URL, so tag helpers will be
automatically prefixed, but you do not need Sprockets,<br>simply set second
argument to `false` when using `assets_url`, or its alias - `assets_map`:

```ruby
app = E.new do
  assets_url '/assets', false
end
```

Now assets are mapped to "/assets" and you can use tag helpers without 
being bothered with Sprockets installation/configuration.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

Assets Mapper
---

Sprockets is doing a great job at loading requirements.

But sometimes you need to load assets from templates rather from Sprockets.

`assets_mapper` allow to avoid repetitive path using when loading assets.

**Example:** - long way:

```ruby
js_tag  'vendor/jquery'

js_tag  'vendor/bootstrap/js/bootstrap'
css_tag 'vendor/bootstrap/css/bootstrap'

js_tag  'vendor/select2/select2.min'
css_tag 'vendor/select2/select2'
```

**Example:** - using `assets_mapper`

```ruby
assets_mapper :vendor do
  js_tag  'jquery'
  
  cd 'bootstrap'
  js_tag  'js/bootstrap'
  css_tag 'css/bootstrap'
  
  cd '../select2'
  js_tag  'select2.min'
  css_tag 'select2'
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**




