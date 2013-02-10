
Espresso features a built-in generator that starts by building a ready-to-use application then allow you to easily create controllers, routes, models and views from command line.

The generator can be used via `e` executable followed by `g` notation and name of the unit to be generated.

Ex: type `e g:project ProjectName` to generate a project, `e g:controller Foo` to generate a controller, etc.

**Worth to note** that generator also allow to use only the first unit letter, ex: `e g:p ProjectName` to generate a project, `e g:c Foo` to generate a controller, etc.

Also, any non-alphanumeric(except space) can be used instead of semicolon, ex: `e g.p ProjectName` to generate a project, `e g.c Foo` to generate a controller, etc.

Or just omit that symbol, ex: `e gp ProjectName` to generate a project, `e gc Foo` to generate a controller, etc.


## Basic project structure

```
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


## Generating Projects

To generate a project simply type:

```
$ e g:p App
```

This will create `./App` folder with a ready-to-use application inside.

Generated application will use `ERB` engine and wont be set to use any `ORM`.

To generate an project that will use a custom engine, use `engine` option followed by a semicolon and the full, case sensitive name of desired engine:

```
$ e g:p App engine:Slim
```

**Worth to note** that generator allow to use only first option letter and require a semicolon between option name and value:

```
$ e g:p App e:Slim
```

This will update your `Gemfile` by adding `slim` gem and also will update `config.yml` by adding `engine: :Slim`.


If your project will use an `ORM`, use `orm` option followed by a semicolon and the name of desired `ORM`:

```
$ e g:p App orm:ActiveRecord
```

**Worth to note** that `ORM` name are case insensitive. You can even use only first letter.

**Also** `orm` option can be shortened to first letter only:

project using ActiveRecord:
```
$ e g:p App orm:a
# or
$ e g:p App orm:ar
# or just
$ e g:p App o:a
```

project using DataMapper:
```
$ e g:p App o:dm
# or just
$ e g:p App o:d
```

project using Sequel:
```
$ e g:p App o:sequel
# or just
$ e g:p App o:s
```

Generator also allow to specify [format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format) to be used by all controllers / actions.

Ex: to make all actions to serve URLs ending in `.html`, use `format:html`:

```
$ e g:p App format:html
```

And of course as per other options, `format` can be shortened to first letter only:

```
$ e g:p App f:html
```

And of course you can pass multiple options:

```
$ e g:p App o:ar e:Slim f:html
```


## Generating Controllers

As simple as:

```
$ e g:c Foo
```

This will create "base/controllers/foo/" folder and "base/controllers/foo_controller.rb" file.

The file will contain controller's setups and the folder will contain controller's actions.

### Map

By default the controller will be mapped to its underscored name, that's it, "Foo" to "/foo", "FooBar" to "/foo_bar", "Foo::Bar" to "/foo/bar" etc.

To generate a controller mapped to a custom location, pass the route using the `route` option:

```
$ e g:c Foo route:bar
# or just
$ e g:c Foo r:bar
```

### Setups

When generating a controller without any setups, it will use project-wide ones(passed at project generation), if any.

To generate a controller with custom setups, pass them as options:

```
$ e g:c Foo e:Haml
```

This will create a controller that will use `Haml` engine.

Another option is [format](https://github.com/espresso/espresso/blob/master/docs/Routing.md#format):

```
$ e g:c Foo f:html
```

### Multiple

When you need to generate multiple controllers at once, use `controllers`(or `cs`) notation:

```
$ e g:controllers A B C
# or just
$ e g:cs A B C
```

This will generate 3 controllers without any setups.

Any passed setups will apply to all generated controllers:

```
$ e g:cs A B C e:Haml 
```

### Namespaces

When you need a namespaced controller, pass its name as is:

```
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
To map it to another url, use `route` option as shown above.






















