class EspressoFrameworkRequest < Rack::Request # partially borrowed from Sinatra Framework

  include EspressoFrameworkConstants

  # getting various setups accepted by browser.
  # `accept?` is for content type, `accept_charset?` for charset etc.
  # as per W3C specification.
  #
  # useful when your API need to know about browser's expectations.
  #
  # @example
  #    accept? 'json'
  #    accept? /xml/
  #    accept_charset? 'UTF-8'
  #    accept_charset? /iso/
  #    accept_encoding? 'gzip'
  #    accept_encoding? /zip/
  #    accept_language? 'en-gb'
  #    accept_language? /en\-(gb|us)/
  #    accept_ranges? 'bytes'
  #
  ['', '_CHARSET', '_ENCODING', '_LANGUAGE', '_RANGES'].each do |field|
    define_method "accept#{field.downcase}?" do |value|
      @__e__accept_entries ||= {}
      @__e__accept_entries[field] ||= env[ENV__HTTP_ACCEPT + field]
      return unless @__e__accept_entries[field]
      @__e__accept_entries[field] =~ value.is_a?(Regexp) ? value : /#{value}/
    end
  end

  # Returns an array of acceptable media types for the response
  def accept
    @__e__accept ||= env[ENV__HTTP_ACCEPT].to_s.split(',').
      map { |e| accept_entry(e) }.sort_by(&:last).map(&:first)
  end

  def preferred_type(*types)
    return accept.first if types.empty?
    types.flatten!
    accept.detect do |pattern|
      type = types.detect { |t| File.fnmatch(pattern, t) }
      return type if type
    end
  end

  alias accept? preferred_type
  alias secure? ssl?

  def forwarded?
    env.include? ENV__HTTP_X_FORWARDED_HOST
  end

  def safe?
    get? or head? or options? or trace?
  end

  def idempotent?
    safe? or put? or delete?
  end

  private

  def accept_entry(entry)
    type, *options = entry.delete(' ').split(';')
    quality = 0 # we sort smallest first
    options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
    [type, [quality, type.count('*'), 1 - options.size]]
  end
end
