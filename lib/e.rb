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

class << E
  private
  # instance_exec at runtime is expensive enough,
  # so compiling procs into methods at load time.
  def proc_to_method *chunks, &proc
    chunks += [self.to_s, proc.to_s]
    name = ('__appetite__e__%s__' % chunks.join('_').gsub(/[^\w|\d]/, '_')).to_sym
    define_method name, &proc
    name
  end
end

class EApp
  include ::AppetiteUtils

  DEFAULT_SERVER = :WEBrick
  DEFAULT_PORT   = 3000
end

class Module
  def mount *roots, &setup
    ::EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end

%w[core helpers view assets cache-manager].each do |dir|
  Dir[$:.first + '/e/' + dir + '/**/*.rb'].each {|f| require f}
end

require 'e/crud'
require 'e/e_app/setup'
require 'e/e_app/base'
