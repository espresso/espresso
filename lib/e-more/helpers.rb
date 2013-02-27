class E

  # build a HTML <a> tag.
  #
  # if first param is a valid action, the URL of given action will be used.
  # action accepted as a symbol or a string representing action name and format.
  # action can also be passed in deRESTified form, eg. :read instead of :post_read
  #
  # @example
  #
  #   class App < E
  #     format '.html'
  #
  #     def read
  #       link_to :read        #=> /app/read
  #       link_to 'read.html'  #=> /app/read.html
  #       link_to 'read.xml'   #=> read.xml - not translated, used as is
  #     end
  #
  #     def post_write
  #       link_to :post_write  #=> /app/write - works but it is tedious, use :write instead
  #       link_to :write       #=> /app/write
  #       link_to 'write.html' #=> /app/write.html
  #       link_to '/something' #=> /something - not translated, used as is
  #     end
  #   end
  #
  # if `nil` passed as first argument, a void link will be created
  #
  # @example
  #
  #   link_to nil, 'something' #=> <a href="javascript:void(null);">something</a>
  #
  # anchor can be passed via second argument.
  # if it is missing, the link will be used as anchor
  # 
  # @example
  #
  #   link_to :something   #=> <a href="/something">/something</a>
  #   link_to :foo, 'bar'  #=> <a href="/foo">bar</a>
  # 
  # anchor can also be passed as a block
  # 
  # @example
  # 
  #   link_to(:foo) { 'bar' }  #=> <a href="/foo">bar</a>
  # 
  # attributes can be passed as a hash via last argument
  # 
  # @example
  # 
  #   link_to :foo, target: '_blank'        #=> <a href="/foo" target="_blank">/foo</a>
  #   link_to :foo, :bar, target: '_blank'  #=> <a href="/foo" target="_blank">bar</a>
  # 
  def link_to action_or_link = nil, anchor = nil, attributes = {}
    action_or_link.is_a?(Hash) && (attributes = action_or_link) && (action_or_link = nil)
    anchor.is_a?(Hash) && (attributes = anchor) && (anchor = nil)
    (route = self.class[action_or_link]) && (action_or_link = route)
    anchor ||= block_given? ? yield : action_or_link
    action_or_link.nil? && (action_or_link = "javascript:void(null);")
    attributes.is_a?(Hash) && attributes = attributes.inject('') do |s,(k,v)|
      s << ' %s="%s"' % [k, escape_html(v)]
    end
    '<a href="%s"%s>%s</a>' % [action_or_link, attributes, anchor]
  end

end
