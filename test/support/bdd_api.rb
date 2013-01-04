module BddApi
  def self.included(base)
    base.class_eval do
      alias it Testing
      alias describe Describe
      alias specify describe
    end
  end
end