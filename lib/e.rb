require 'digest'
require 'fileutils'
require 'cgi'
require 'erb'

require 'rubygems'
require 'tilt'
require 'appetite'

class E < Appetite
  
end

class EApp
  module Setup
    
    include ::AppetiteUtils
    include ::AppetiteHelpers    
  end
end

class Module
  def mount *roots, &setup
    ::EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end

require 'e/class'
require 'e/instance'
require 'e/helpers/crud'
require 'e/helpers/view'
require 'e/helpers/cache'
require 'e/helpers/assets'
require 'e/app'
