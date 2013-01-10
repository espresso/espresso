require 'digest'
require 'rubygems'
require 'specular'
require 'sonar'
require 'slim'
require 'haml'

$:.unshift ::File.expand_path('../../lib', __FILE__)
require 'e'
require 'e-ext'
require './test/support/http_spec_helper'
