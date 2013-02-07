require 'digest'
require 'stringio'
require 'rubygems'
require 'specular'
require 'sonar'
require 'slim'
require 'haml'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'e'
require 'e-ext'
require 'e-more/generator'
require './test/support/http_spec_helper'

GENERATOR__DST_ROOT = File.expand_path('../e-more/generator/sandbox', __FILE__) + '/'
