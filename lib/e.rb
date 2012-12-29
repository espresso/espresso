# encoding: UTF-8
require 'digest'
require 'fileutils'
require 'cgi'
require 'erb'

require 'rubygems'
require 'rack'
require 'tilt'

require 'e/constants'
require 'e/utils'

class E
  include Rack::Utils
  include EspressoFrameworkConstants
end

class << E
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
end

module EspressoFrameworkSetup
  include EspressoFrameworkConstants
end

class EApp
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
end

class Module
  def mount *roots, &setup
    EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end

require 'e/map/setup'
require 'e/map/base'
require 'e/map/actions'

require 'e/app/setup'
require 'e/app/base'

require 'e/run/setup'
require 'e/run/base'
require 'e/run/cookies'
require 'e/run/halt'
require 'e/run/redirect'
require 'e/run/request'
require 'e/run/send_file'
require 'e/run/session'
require 'e/run/stream'
require 'e/run/helpers'

require 'e/view/setup'
require 'e/view/base'
require 'e/view/e_app'

require 'e/rewriter'

class E
  include EspressoFrameworkSetup
end

class << E
  EspressoFrameworkSetup.instance_methods.each do |meth|
    define_method meth do |*args, &proc|
      add_setup(:a) { self.send meth, *args, &proc }
    end
  end
end
