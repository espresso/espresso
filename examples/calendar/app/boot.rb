require 'digest'
require 'date'

require 'rubygems'
require 'bundler/setup'
Bundler.require :default # requiring gems in default group

module ECalendar
  # All controllers/models will go under ECalendar namespace.
  # This will allow to  mount calendar into any Espresso app.
end

# current dir
wd = File.expand_path('..', __FILE__) + '/'

# adding current dir to search path
$:.unshift wd

# as current dir is in search path now,
# we can load files in current folder with easy like this:
require 'model/entry'
require 'controller/admin'
require 'controller/index'

# connecting to database
DataMapper.setup(:default, 'mysql://dev@localhost/dev_ECalendar')

# above we loaded all models.
# to make them work properly, we have to finalize them.
DataMapper.finalize

# above we loaded all controllers.
# let's build the de-facto Espresso app:
ECalendarApp = EApp.new do
  
  # instructing app to keep sessions in memory
  session :memory

  # instructing app to serve our assets at /assets base URL.
  assets_url '/assets', true # if true omitted, assets wont be  served

  # by default Espresso will search for assets in ./assets/ folder.
  # but our assets are placed in ../public/ folder, so letting Espresso know about this.
  assets_fullpath wd + '../public'

  # some Rack middleware
  use Rack::ShowExceptions
  use Rack::CommonLogger

  # mounting controllers inside ECalendar module.
  mount ECalendar
end

# when we have some common setup for all(or some) controllers,
# we do not repeatedly put that setup inside each controller.
# instead we setup them all at once at app level.
ECalendarApp.setup do |ctrl|

  # both controllers use same engine,
  # do the same on :index action,
  # and the same on :entries action,
  # so no need to repeatedly type this on both of them

  engine :Slim

  def index
    render
  end

  def entries date = nil
    date = date ? (Time.parse(date) rescue Time.now) : Time.now
    @ymd = [date.year, date.month, date.day]
    date_range = DateTime.new(*@ymd)..DateTime.new(*@ymd, 23, 59, 59)
    @items = ECalendar::EntryModel.all(occur_at: date_range)
    render_p :entries
  end

end
