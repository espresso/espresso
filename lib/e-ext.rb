# to run a slice without explicitly building a new app,
# require e-ext and call SliceName.run(:some => :opts).
# 
# @example
#   require 'e'
#   require 'e-ext'
#  
#   module Cms
#     class Articles < E
#       # ...
#     end
#     class News < E
#       # ...
#     end
#   end
#   Cms.run :server => :Thin, :port => 9292
#
class Module
  def mount *roots, &setup
    EBuilder.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end
