
Espresso features a built-in generator that starts by building a ready-to-use application then allow you to easily create controllers, routes, models and views from command line.

The generator can be used via `e` executable followed by `g` notation and name of the unit to be generated.

Ex: type `e g:project ProjectName` to generate a project, `e g:controller Foo` to generate a controller, etc.

**Worth to note** that generator also allow to use only the first unit letter, ex: `e g:p ProjectName` to generate a project, `e g:c Foo` to generate a controller, etc.

Also, any non-alphanumeric(except space) can be used instead of semicolon, ex: `e g.p ProjectName` to generate a project, `e g.c Foo` to generate a controller, etc.

Or just omit that symbol, ex: `e gp ProjectName` to generate a project, `e gc Foo` to generate a controller, etc.


## Basic project structure

```
` - base/
    ` - controllers/
    ` - helpers/
    ` - models/
    ` - specs/
    ` - views/
    ` - boot.rb
    ` - config.rb
    ` - database.rb

` - config/
    ` - config.yml
    ` - database.yml

` - public/
    ` - assets/
        ` - app.css
        ` - app.js

` - tmp/

` - var/
    ` - db/
    ` - log/
    ` - pid/

` - Gemfile
` - app.rb
` - config.ru
```



## Generating Projects

To generate a project simply type:

```
$ e g:p App
```

This will create `./App` folder with a ready-to-use application inside.

Generated application will use `ERB` engine and wont be setup to use any `ORM`.

To generate an project that will use a custom engine, pass `engine` option:

```
$ e g:p App engine:Slim
```

**Worth to note** that generator allow to use only first option letter and require a semicolon between option name and value:

```
$ e g:p App e:Slim
```

This will update your `Gemfile` by adding `slim` gem and also will update `config.yml` by adding `engine: :Slim`.


