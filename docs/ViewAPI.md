
# Setup

## Engine


Template engine can be set globally, at class level, then inside actions you simply call `render` and counterparts.

This way you can change your engine for an entire app with minimal impact, without refactoring a single action.

By default Espresso uses ERB template engine.

**Example:** - Set :Erubis for current controller

```ruby
class App < E
    # ...
    engine :Erubis
end
```

**Example:** - Set :Haml for an entire slice

```ruby
module App
    class News < E
        # ...
    end

    class Articles < E
        # ...
    end
end

app = App.mount do
    engine :Haml
end
app.run
```

If engine requires some arguments/options, simple pass them as consequent params.

Just like

```ruby
engine :SomeEngine, :some_arg, :some => :option
```

**Example:** - Set default encoding

```ruby
engine :Erubis, default_encoding: Encoding.default_external
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Extension


Espresso will use the default extension of current engine.

To set a custom extension, use `engine_ext`.

**Example:**

```ruby
class App < E
    # ...

    engine :Erubis
    engine_ext :xhtml
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Templates path


By default, Espresso will look for templates in "view/" folder, inside your app root.

If that's not your case, use `view_path` to inform Espresso about correct path.

**Example:**

```ruby
class App < E
    map '/cms'

    view_path 'base/view'

    def index
        # ...
        render # this will render base/view/cms/index.erb
    end

    def books__free
        # ...
        render # this will render base/view/cms/books/free.erb
    end
end
```

For cases when your templates are placed out of app root,
provide an absolute path to templates, i.e., a path starting with a slash.

**Example:**

```ruby
class News < E

    view_path File.expand_path '../../../shared-templates', __FILE__
    # ...
end
```

If app deployed on a non-Unix-like system, you should use `view_fullpath` instead.

**Example:**

```ruby
class News < E

    view_fullpath File.expand_path '../../../shared-templates', __FILE__
    # ...
end
```



**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Layouts path


By default, Espresso will look for layouts in same folder as templates, i.e., in "view/"

Use `layouts_path` to set a custom path to layouts.<br/>
The path should be relative to templates path.

**Example:** - Search layouts in "view/layouts/"

```ruby
class App < Ruby
    # ...
    layouts_path 'layouts/'
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Layout


By default no layouts will be searched/rendered.

You can instruct Espresso to render a layout by using `layout`

**Example:** - All actions will use :master layout

```ruby
class App < Ruby
    # ...
    layout :master
end
```


**Example:** - Only :signin and :signup actions will use :member layout

```ruby
class App < Ruby
    # ...
    setup :signin, :signup do
        layout :member
    end
end
```

To make some action ignore layout rendering, use `layout false`

**Example:** - All actions, but :rss, will use layout

```ruby
class App < Ruby
    # ...
    layout :master
    setup :rss do
        layout false
    end
end
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


# Render

## Rendering Templates

To *render the template of current action*, simply call `render` or `render_partial` without arguments.

```ruby
class App < E
  
  map 'news'
  view_path 'base/views'
  layout :master
  engine :Haml

  def some_action
      # ...
      render  # will render base/views/news/some_action.haml, using :master layout
  end

  def some__another_action
      # ...
      render_partial  # will render base/views/news/some__another_action.haml, without layout
  end

end
```

**=== Important ===** Template name should exactly match the name of current action, including REST verb, if any.

```ruby
def get_latest
  render # will try to render base/views/news/get_latest.haml
end

def post_latest
  render # will try to render base/views/news/post_latest.haml
end
```

Also, if current action called with a specific format, template name should contain it.

```ruby
class App < E
  
  map '/'
  format :xml, :html

  def post_latest
    render  # on /latest      it will render view/post_latest.erb
            # on /latest.xml  it will render view/post_latest.xml.erb
            # on /latest.html it will render view/post_latest.html.erb
  end
end
```


To *render a template by name*, pass it as first argument.

```ruby
render :some__another_action      # will render base/views/news/some__another_action.haml

render_partial 'some_action.xml'  # will render base/views/news/some_action.xml.haml

render 'some-template'            # will render base/views/news/some-template.haml

render_p 'some-template.html'     # will render base/views/news/some-template.html.haml
```


To render a template located higher than your current action, use `../`:

```ruby
class App < E
  map :pages

  view_path 'templates'
  
  def some_meth
    render                   # will render templates/pages/some_meth
    render '../some-file'    # will render templates/some-file
  end
end
```


To *render a template of inner controller*, pass controller as first argument and the template as second.

```ruby
class Articles < E
  
  view_path 'templates'
  engine :Slim
  # ...
end

render Articles, :most_popular         # will render templates/articles/most_popular.slim
render Articles, 'some-template.xml'   # will render templates/articles/some-template.xml.slim
```


*Scope* and *Locals* can be passed as consequent arguments, orderlessly.<br/>
The scope is defaulted to the current controller and locals to an empty Hash.


As *extension* will be used the explicitly defined extension(at class level)
or the default extension of used engine.

**Layout**

*   If current action rendered, layout of current action will be used, if any.
*   If custom action rendered, layout of given action will be used, if any.
*   If an arbitrary template rendered, layout of current action will be used, if any.

**Engine**

As engine will be used the effective engine for current context.<br/>
Meant engine defined for current or given action,
or engine defined for all actions,
or default engine - ERB.


**Inline rendering**

If block given, the template will not be searched/rendered.<br/>
Instead, the string returned by the block will be rendered.<br/>
This way you'll can render data from DB directly, without saving it to a file.


**=== Important ===** If custom controller given, rendering methods will use the path, engine and layout set by given controller.


**=== Important ===** Espresso wont support custom file extensions!

So you can not render a template like this: `render "template.haml"`.

Instead use `render "template"` and the extension will be added automatically,
based on extension given or computed at class level.

Espresso will guess extension by used engine, like '.haml' for Haml, '.erb' for Erubis etc.<br/>
If your templates uses a custom extension, set it via `engine_ext`.
  
However, if you have a file with a extension that is not typical for used engine
nor match the extension given via `engine_ext`, please consider to rename the file.

Computing file extensions would add extra unneeded overhead.<br/>
The probability of custom extensions are ephemeral
and it is quite irrational to slow down an entire framework 
just to handle such a negligible probability.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Rendering Layouts


`render_layout` will render the layout of current(or given) action or an arbitrary layout file.


*Render the layout of current action*

```ruby
render_layout { 'some string' }
```

*Render the layout of current action within custom scope*

```ruby
render_layout Object.new do
    'some string'
end
```

*Render the layout of current action within custom scope and locals*

```ruby
render_layout Object.new, :some_var => "some val" do
    'some string'
end
```

*Render the layout of :news action*

```ruby
render_layout :news do
    'some string'
end
```

*Render the .html layout of :news action*

```ruby
render_layout 'news.html' do
    'some string'
end
```

*Render layout of :latest action of News controller*

```ruby
render_layout News, :latest do
    'some string'
end
```


*Render an arbitrary file as layout*

```ruby
render_layout 'layouts/master' do
    'some string'
end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Ad hoc rendering

Any of `render`, `render_partial` and `render_layout` methods has ad hoc counterparts,
like `render_haml`, `render_erb_partial`, `render_liquid_layout` and so on.

Works exactly as common rendering methods except they are using a custom engine and extension.

Used when you need to "quickly" render a template, without any previous class-level setups.

```ruby
render_haml        # will render the template and layout of current action using Haml engine

render_haml_p      # will render only the template of current action using Haml engine

render_haml_l      # will render only the layout of current action using Haml engine
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Path Resolver

Espresso looking for templates in the following way:

<code>
view path / controller's base URL / action name or given template
</code>

Sample Example:

```ruby
class Index < E
  map '/'

  def index
    render_partial 'layouts/_header'
    # will render ./templates/layouts/_header.erb as path is built like:
    # templates(view path) + /(controller's base URL) + layouts/_header(given path)
  end
end

class Products < E
  map 'products'

  def index
    render_partial 'layouts/_header'
    # will try to render ./templates/products/layouts/_header.erb and fail cause path is built like:
    # templates(view path) + products(controller's base URL) + layouts/_header(given path)
  end
end

app = EApp.new :automount
app.setup do |ctrl|
  view_path 'templates'
  layouts_path 'layouts'
  layout :base
end
```

There are 2 reasons why `Products#render_partial` is failing:

  - real - template not found
  - conceptual - using strings repeatedly is a Unacceptable bad practice

Just imagine what happens if you want to change `layouts_path` from `layouts` to something else.

You then have to search/replace all related paths in your templates!

To sort this out, Espresso offers 2 instance methods: `view_path` and `layouts_path` 
that will return path to templates ignoring controller's base URL, 
that's it, full path to templates without controller's base URL.

So to make previous `Products#render_partial` to work we do like this:

```ruby
class Products < E
  map 'products'

  def index
    render_partial layouts_path('_header')
    # will render ./templates/layouts/_header.erb cause path is built like:
    # templates(view path) + layouts(layouts path) + _header(given path)
  end
end
```

**Worth to note:** both methods accept multiple arguments that will be joined and appended to returned path:

```ruby
view_path 'some', 'path', 'to', 'some-file' # view/some/path/to/some-file
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Templates Compilation


For most web sites, most time are spent at templates rendering.<br/>
When rendering templates, most time are spent at files reading and templates compilation.

You can skip these expensive operations by using built-in compiler.

It will simply store compiled templates in memory and on consequent requests will just render them,
avoiding filesystem calls for reading and CPU time for compiling templates.

To use compiler you should simply pass a key/value pair to locals.<br/>
The key should be an empty string and the value an unique ID or simply true.

**Example:**

```ruby
render '' => true

render_partial :some_action, '' => true

render_partial :some_action, '' => :some_action, :foo => :bar

render_file 'some/file', Object.new, '' => true

render_haml "path/to/file", '' => "path/to/file"
```

To clear compiled templates call `clear_compiler!`.<br/>
If called without arguments, it will clear all templates.<br/>
To clear only some templates, pass their unique IDs as arguments.

**Example:**

```ruby
class App < E

    def index
        @banners = render_view :banners, '' => :banners
        @ads = render_view :ads, '' => :ads
        render '' => true
    end

    before do
        if 'some condition occurred'
            # updating only @banners and @ads
            clear_compiler! :banners, :ads
        end
        if 'some another condition occurred'
            # clear all templates
            clear_compiler!
        end
    end
end
```

By using `clear_compiler_like!` you can clear only keys that match a given regexp or even array.

```ruby
def index
    @procedures = render :procedures,      '' => [user, :procedures]
    @actions    = render :actions,         '' => [user, :actions]
    @banners    = render_partial :banners, '' => :user_banners
    render
end

private
def clear_compiled_templates

    # clearing [user, :procedures] and [user, :actions]
    clear_compiler_like! [user]

    # clearing any templates starting with 'user'
    clear_compiler_like! /\Auser_/

end
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
