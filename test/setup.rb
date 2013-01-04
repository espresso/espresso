require 'rubygems'
require 'specular'
require 'sonar'
require 'slim'
require 'haml'

$:.unshift ::File.expand_path('../../lib', __FILE__)
require 'e'
require './test/support/bdd_api'
require './test/support/http_spec_helper'
