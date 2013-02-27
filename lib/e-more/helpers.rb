class E

  def link_to action_or_link = nil, label = nil, attributes = {}
    action_or_link.is_a?(Hash) && (attributes = action_or_link) && (action_or_link = nil)
    label.is_a?(Hash) && (attributes = label) && (label = nil)
    (route = self.class[action_or_link]) && (action_or_link = route)
    label ||= begin
      block_given? ? yield : action_or_link
    end
    action_or_link.nil? && (action_or_link = "javascript:void(null);")
    attributes.is_a?(Hash) && attributes = attributes.inject('') do |s,(k,v)|
      s << ' %s="%s"' % [k, escape_html(v)]
    end
    '<a href="%s"%s>%s</a>' % [action_or_link, attributes, label]
  end

end
