
require 'digest'
require 'stringio'

require 'specular'
require 'sonar'
require 'slim'
require 'json'
require 'rabl'
require 'haml'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'e'
require 'e-ext'

Dir['./test/support/*.rb'].each {|f| require f}
