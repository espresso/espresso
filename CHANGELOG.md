
+ 0.4 [Feb 11 2013] - First Stable Release

  - Created a handy generator to easily generate projects, controllers, routes etc.
  - Path to templates are now resolved by controller name, not by base URL
  - Verbified actions has priority over verbless ones, regardless defining order
  - Removing Appetite dependency
  - Writing a new router crafted for specific Espresso needs. Also it tends to be faster than Rack::URLMap
  - Rewrite rules can now be defined inside controllers
  - Splitting codebase into `e-core` and `e-more`
  - Moved monkey-patches to e-ext
  - `format` now accepts only formats, not action names.
  - Added `format_for` to define formats for specific action.
  - Added `disable_format_for` to disable formats for specific action.
  - Sprockets support
  - `assets_loader` renamed to `assets_mapper`
  - Added tag helpers like `js_tag`, `css_tag`, `png_tag` etc.
  - Slim engine are now automatically registered without errors
  - Dropped support for inter-controller rendering
  - Added `render_file` method
  - Fixed Crudifier to work well with ActiveRecord models
  - `route` are now RESTful friendly
  - Allow to include actions from modules
  - Accept multiple controllers at mount
  - `invoke` and `fetch` will NOT pass actual params. Only `pass` will do.
  - Considerable code cleanup and refactoring. Special thanks to @mindreframer.
