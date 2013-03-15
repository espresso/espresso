require 'digest'
require 'stringio'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'e'
require 'e-ext'
require 'specular'
require 'sonar'
require 'json'
require 'haml'
require 'slim'
require 'rabl'

Dir['./test/support/*.rb'].each {|f| require f}
