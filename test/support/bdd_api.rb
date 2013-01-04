module BddApi
  def self.included(base)
    base.class_eval do
      alias it Testing
      alias describe Describe
      alias specify describe
      alias testing Testing
    end
  end
end