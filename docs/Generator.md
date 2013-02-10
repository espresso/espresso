
Espresso features a built-in generator that starts by building a ready-to-use application then allow you to easily create controllers, routes, models and views from command line.

The generator can be used via `e` executable followed by `g` notation and name of the unit to be generated.

Ex: type `e g:project ProjectName` to generate a project, `e g:controller Foo` to generate a controller, etc.

**Worth to note** that generator allow to use only the first unit letter, ex: `e g:p ProjectName` to generate a project, `e g:c Foo` to generate a controller, etc.

Also, any non-alphanumeric(except space) can be used instead of semicolon, ex: `e g.p ProjectName` to generate a project, `e g.c Foo` to generate a controller, etc.

Or just omit that symbol, ex: `e gp ProjectName` to generate a project, `e gc Foo` to generate a controller, etc.


## Basic project structure

```bash
- base/
  | - controllers/
  | - helpers/
  | - models/
  | - specs/
  | - views/
  | - boot.rb
  | - config.rb
  ` - database.rb

- config/
  | - config.yml
  ` - database.yml

- public/
  | - assets/
      | - app.css
      ` - app.js

- tmp/

- var/
  | - db/
  | - log/
  ` - pid/

- Gemfile
- app.rb
- config.ru
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Generating Projects

To generate a project simply type:

```bash
$ e g:p App
```

This will create `./App` folder with a ready-to-use application inside.

Generated application will use `ERB` engine and wont be set to use any `ORM`.

To generate a project that will use a custom engine, use `engine` option followed by a semicolon and the full, case sensitive, name of desired engine:

```bash
$ e g:p App engine:Slim
```

**Worth to note** that generator allow to use only first option letter and require a semicolon between option name and value:

```bash
$ e g:p App e:Slim
```

This will update your `Gemfile` by adding `slim` gem and also will update `config.yml` by adding `engine: :Slim`.


If your project will use an `ORM`, use `orm` option followed by a semicolon and the name of desired `ORM`:

```bash
$ e g:p App orm:ActiveRecord
```

**Worth to note** that `ORM` name are case insensitive. You can even use only first letter.

**Also** `orm` option can be shortened to first letter only:

project using ActiveRecord:
```bash
$ e g:p App orm:a
# or
$ e g:p App orm:ar
# or just
$ e g:p App o:a
```

project using DataMapper:
```bash
$ e g:p App o:dm
# or just
$ e g:p App o:d
```

project using Sequel:
```bash
$ e g:p App o:sequel
# or just
$ e g:p App o:s
```

Generator also allow to specify [format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format) to be used by all controllers / actions.

Ex: to make all actions to serve URLs ending in `.html`, use `format:html`:

```bash
$ e g:p App format:html
```

And of course as per other options, `format` can be shortened to first letter only:

```bash
$ e g:p App f:html
```

And of course you can pass multiple options:

```bash
$ e g:p App o:ar e:Slim f:html
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Generating Controllers

As simple as:

```bash
$ e g:c Foo
```

This will create "base/controllers/foo/" folder and "base/controllers/foo_controller.rb" file.

The file will contain controller's setups and the folder will contain controller's actions.

### Map

By default the controller will be mapped to its underscored name, that's it, "Foo" to "/foo", "FooBar" to "/foo_bar", "Foo::Bar" to "/foo/bar" etc.

To generate a controller mapped to a custom location, use the `route` option:

```bash
$ e g:c Foo route:bar
# or just
$ e g:c Foo r:bar
```

### Setups

When generating a controller without any setups, it will use project-wide ones(passed at project generation), if any.

To generate a controller with custom setups, pass them as options:

```bash
$ e g:c Foo e:Haml
```

This will create a controller that will use `Haml` engine.

Another option is [format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format):

```bash
$ e g:c Foo f:html
```

### Multiple

When you need to generate multiple controllers at once, use `controllers`(or `cs`) notation:

```bash
$ e g:controllers A B C
# or just
$ e g:cs A B C
```

This will generate 3 controllers without any setups.

Any passed setups will apply to all generated controllers:

```bash
$ e g:cs A B C e:Haml 
```

### Namespaces

When you need a namespaced controller, pass its name as is:

```bash
$ e g:c Foo::Bar
```

This will generate `Foo` module with `Bar` class inside:

```ruby
module Foo
  class Bar
    # ...
  end
end
``` 

**Worth to note** that `Bar` controller will be mapped to "/foo/bar" URL.<br>
To map it to another location, use `route` option as shown above.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**


## Generating Routes

As simple as:

```bash
$ e g:route Foo bar
# or just
$ e g:r Foo bar
```

where `Foo` is the controller name and `bar` is the route.

This will create "base/controllers/foo/bar_action.rb" and "base/views/foo/bar.erb" files.

### Mapping

You can provide the URL rather than action name - it will be automatically converted according to effective [path rules](https://github.com/espresso/espresso/blob/master/docs/Routing.md#action-mapping):

```bash
$ e g:r Forum posts/latest
```

This will create `posts__latest` method in "base/controllers/forum/posts__latest_action.rb" file and the "base/views/forum/posts__latest.erb" template file.

See [more details on actions mapping](https://github.com/espresso/espresso/blob/master/docs/Routing.md#action-mapping).

### Setups

Setups provided at route generation will be effective only on generated route:

```bash
$ e g:c Foo e:Haml
$ e g:r Foo bar e:Slim
```

All actions of `Foo` controller, except `bar`, will use `Haml` engine.<br>
`bar` action will use `Slim` engine instead.

### Arguments

If generated route are supposed to accept some arguments, simply pass them after route name:

```bash
$ e g:r Foo bar a b=nil
```

will result in:

```ruby
class Foo

  def bar a, b=nil
  end
end
```

**Worth to note** that any setups can be provided alongside arguments, they wont clash:

```bash
$ e g:r Foo bar a b=nil e:Haml f:html
```

will result in:

```ruby
class Foo
  
  format_for :bar, 'html'
  before :bar do
    engine :Haml
  end

  def bar a, b=nil
  end
end
```

### Multiple

To generate multiple routes at once use `routes` or `rs` notation:

```bash
$ e g:rs Foo a b c
```

this will create 3 routes and 3 views.

**Worth to note** that any provided setups will apply on all generated actions. **Not** the same about arguments, they will be interpreted as action names, so do not pass any arguments when generating multiple routes.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Generating Models

```bash
$ e g:m Foo
```

this will create "base/models/foo.rb" file.

File content will depend on setups passed at project generation:

If we generate a project like this:
```bash
$ e g:p App o:ActiveRecord
```

the:
```bash
$ e g:m Foo
```

will result in:

```ruby
class Foo < ActiveRecord::Base

end
```

And if the project are generated like this:
```bash
$ e g:p App o:DataMapper
```

the:
```bash
$ e g:m Foo
```

will result in:

```ruby
class Foo
  include DataMapper::Resource

  property :id, Serial
end
```

To generate a model on a project without default `ORM`, use `orm` option at model generation:


```bash
$ e g:m Foo orm:ActiveRecord
```

will result in:

```ruby
class Foo < ActiveRecord::Base

end
```

To generate multiple models at once, use `models` or `ms` notation:

```bash
$ e g:ms A B C
```

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**

## Generating Views

View generator are triggered every time you generate a route, so use it only to create a template that was accidentally lost:

```bash
$ e g:v Foo bar
```

this will create "base/views/foo/bar.ext" template, if it does not exists.

If template already exists, the generator will simply touch it, without modifying the name/content in any way.

**[ [contents &uarr;](https://github.com/espresso/espresso#tutorial) ]**











