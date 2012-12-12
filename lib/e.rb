require 'digest'
require 'fileutils'
require 'cgi'
require 'erb'

require 'rubygems'
require 'appetite'
require 'tilt'

class E < Appetite
  CONTENT_TYPE__DEFAULT      = 'text/html'.freeze
  CONTENT_TYPE__EVENT_STREAM = 'text/event-stream'.freeze
  VIEW__DEFAULT_PATH         = 'view/'.freeze
end

class Module
  def mount *roots, &setup
    ::EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end

require 'e/setup'
require 'e/base'


require 'e/helpers/action_handling'
require 'e/helpers/assets'
require 'e/helpers/cache'
require 'e/helpers/callbacks'
require 'e/helpers/cookies'
require 'e/helpers/crud'
require 'e/helpers/header_content'
require 'e/helpers/html'
require 'e/helpers/http_cache_control'
require 'e/helpers/http_stati'
require 'e/helpers/ipcm'
require 'e/helpers/restrictions'
require 'e/helpers/session'
require 'e/helpers/stream'
require 'e/helpers/view'
require 'e/app'
