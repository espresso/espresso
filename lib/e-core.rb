require 'digest'
require 'fileutils'
require 'cgi'
require 'erb'

require 'rubygems'
require 'rack'
require 'tilt'

require 'e-core/constants'
require 'e-core/utils'
require 'e-core/rewriter'

class E
  include Rack::Utils
  include EspressoFrameworkConstants
end

class << E
  include EspressoFrameworkConstants
  include EspressoFrameworkUtils
  
  def define_setup_method meth
    (class << self; self end).class_exec do
      define_method meth do |*args, &proc|
        add_setup(:a) { self.send meth, *args, &proc }
      end
    end
  end
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

require 'e-core/controller/setup'
require 'e-core/controller/base'
require 'e-core/controller/actions'

require 'e-core/app/setup'
require 'e-core/app/base'

require 'e-core/instance/setup'
require 'e-core/instance/base'
require 'e-core/instance/cookies'
require 'e-core/instance/halt'
require 'e-core/instance/redirect'
require 'e-core/instance/request'
require 'e-core/instance/send_file'
require 'e-core/instance/session'
require 'e-core/instance/stream'
require 'e-core/instance/helpers'
