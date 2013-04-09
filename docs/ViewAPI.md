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

Just like:

```ruby
engine :SomeEngine, :some_arg, :some => :option
```

**Example:** - Set default encoding

```ruby
engine :Erubis, :default_encoding => Encoding.default_external
```


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Extension


Espresso will use the default file extension of current engine(.haml for Haml, .erb for ERB etc)

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
class Cms < E

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

For cases when your templates are placed out of app root
you should provide absolute path to templates by using `view_fullpath`:


```ruby
class News < E

  view_fullpath File.expand_path('../../../shared-templates', __FILE__)
  # ...
end
```

**IMPORTANT:** As of version 0.4.2 Espresso will use underscored controller name to resolve path to templates. Before 0.4.2, base URL were used for this:


```ruby
class Cms < E
  map '/pages'

  def index
    render
    # starting with 0.4.2 will render "view/cms/index.erb"
    # before 0.4.2 - "view/pages/index.erb"
  end
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
  format '.xml', '.html'

  def post_latest
    render  # on /latest      it will render view/post_latest.erb
            # on /latest.xml  it will render view/post_latest.xml.erb
            # on /latest.html it will render view/post_latest.html.erb
  end
end
```


To *render a template by name*, pass it as first argument.

```ruby
class App < E
  engine :Haml

  def index
    render_partial 'some_action.xml'  # will render base/views/news/some_action.xml.haml
   
    render :some__another_action      # will render base/views/news/some__another_action.haml

    render 'some-template'            # will render base/views/news/some-template.haml

    render_p 'some-template.html'     # will render base/views/news/some-template.html.haml
  end
end
```


*Scope* and *Locals* can be passed as arguments.<br/>
The scope is defaulted to the current controller and locals to an empty Hash.

**Example:**

```ruby
class App < E
  
  def some_action
    
    render Sandbox.new(params)  # will render template within custom scope
    
    render :foo => :bar         # will add `foo` for local variables inside template
    
    render Sandbox.new(params), :foo => :bar # custom scope with additional local variables

    # render given template within custom scope with additional local variables
    render 'template-name', Sandbox.new(params), :foo => :bar
    
  end
end
```

As *extension* will be used the explicitly defined extension
or the default extension of used engine.


**Layout**

*   If current action rendered, layout of current action will be used, if any.
*   If an arbitrary template rendered, layout of current action will be used, if any.

**Engine**

As engine will be used the effective engine for current action.


**Inline rendering**

If block given, template will not be searched.<br/>
Instead, the string returned by the block will be rendered.<br/>
This way you'll can render data from DB directly, without saving it to a file.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Rendering Layouts


`render_layout` will render the layout of current action or an arbitrary layout file.


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

Works exactly as other rendering methods except they are using a custom engine and extension.

Used when you need to "quickly" render a template, without any previous setups.

```ruby
render_haml        # will render the template and layout of current action using Haml engine

render_haml_p      # will render only the template of current action using Haml engine

render_haml_l      # will render only the layout of current action using Haml engine
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Path Resolver

Espresso is building the path to templates as follow:

<code>
view path / controller's name / action name or given template
</code>

```ruby
class Index < E
  map '/'

  def index
    render
    # will render ./view/index/index.erb
  end

  def header
    render_partial 'banner'
    # will render ./view/index/banner.erb
  end
end
```

**Note:** before 0.4 base URL were used instead of controller name.

If your templates are located in a folder different from your controller name,
use `view_prefix` to set correct path:

```ruby
class Index < E
  map '/'
  view_prefix '/'

  def index
    render
    # will render ./view/index.erb instead of ./view/index/index.erb
  end

  def header
    render_partial 'banner'
    # will render ./view/banner.erb instead of ./view/index/banner.erb
  end
end
```

As you can see, Espresso will automatically add file extension,
based on value defined via `engine_ext` or engine's default extension.


To render a template by full name, use `render_file`:

```ruby
class Index < E
  map '/'

  def index
    render_file 'banners/top.xhtml' # will render ./view/banners/top.xhtml

    render_partial 'banners/top'    # will render ./view/index/banners/top.erb
  end

end
```

Please note that `render_file` renders templates without layout.

It is also possible to render layouts by full name:

```ruby
render_layout_file 'layouts/_header.html.haml' do
  some content
end
# will render ./view/layouts/_header.html.haml
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Templates Compilation


For most web sites, most time are spent at templates rendering.<br/>
When rendering templates, most time are spent at files reading and templates compilation.

You can skip these expensive operations by using built-in compiler.

It will simply store compiled templates in memory and on consequent requests will just render them, avoiding filesystem calls for reading and CPU time for compiling templates.

As of version "0.4.3", compiler are enabled by default.

Before "0.4.3" you have to enable it manually by using `compiler_pool` at app level:

```ruby
class App < E

  # actions here will use view compiler
end

app = E.new do
  compiler_pool Hash.new
  mount App
end
app.run
```

To clear compiled templates call `clear_compiler!`.


**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**
