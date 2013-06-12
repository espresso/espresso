class EBuilder

  # displays URLs the app will respond to,
  # with controller and action that serving each URL.
  def url_map
    mount_controllers!
    URLMapPrinter.new(sorted_routes)
  end
  alias urlmap url_map

  unless defined?(EBuilder::URLMapPrinter)
    class URLMapPrinter

      def initialize routes
        @routes = routes.freeze
      end

      def to_s
        out = ''
        @routes.each do |(*,route,route_setup)|
          out << "%s\n" % route.source
          route_setup.each_pair do |rm,rs|
            out << "  %s%s" % [rm, ' ' * (10 - rm.to_s.size)]
            out << "%s\n" % (rs[:rewriter] || rs[:application] || [rs[:controller], rs[:action]]*'#')
          end
          out << "\n"
        end
        out
      end

      def inspect
        @routes
      end
    end
  end

  private

  def matched_path_info matches
    matches[1].to_s + matches[2].to_s # 2x faster than matches[1..2].join
  end

  def sorted_routes
    @routes.sort do |a,b|
      b[1].source.size <=> a[1].source.size # sorting by size, high to low
    end.sort do |a,b|
      a[0] <=> b[0] # sorting by priority, low to high
    end
  end

  def index_routes controller, initial_priority = 2
    controller.routes.inject([]) do |routes,(*,r,rs)|
      rs.values.first[:action] == INDEX_ACTION ? routes.push(r) : routes
    end.sort {|a,b| b.source.size <=> a.source.size}.inject({}) do |map,r|
      map.merge r => (initial_priority += 1)
    end
  end

  def handle_format formats, path_info
    format = nil
    if formats.any?
      if format = formats[path_info]
        path_info = ''
      elsif format = formats[File.extname(path_info)]
        # File join + dirname + basename
        # is faster than building a regexp and sub path info based on it
        path_info = File.join File.dirname(path_info), File.basename(path_info, format)
      end
    end
    [format, path_info]
  end
  
  def valid_route_context? route_setup, request_method
    route_setup[request_method] || route_setup[:*]
  end

  def rewriter? route_setup
    (setup = route_setup[HTTP__DEFAULT_REQUEST_METHOD]) && setup[:rewriter]
  end

  def valid_rewriter_context? overall_setup, request_method
    (request_method == HTTP__DEFAULT_REQUEST_METHOD ||
      request_method == HTTP__HEAD_REQUEST_METHOD)  &&
      overall_setup[HTTP__DEFAULT_REQUEST_METHOD]
  end

  def valid_host? accepted_hosts, env
    http_host, server_name, server_port =
      env.values_at(ENV__HTTP_HOST, ENV__SERVER_NAME, ENV__SERVER_PORT)
    accepted_hosts[http_host] ||
      accepted_hosts[server_name] ||
      http_host == server_name ||
      http_host == server_name+':'+server_port # 3x faster than create and join an array
  end

  def normalize_path path
    (path_ok?(path) ? path : '/' << path).freeze
  end

  # checking whether path is empty or starts with a slash
  def path_ok? path
    # comparing fixnums are much faster than comparing strings
    path.hash == (@empty_string_hash ||= '' .hash) || # faster than path.empty?
      path[0].hash == (@slash_hash   ||= '/'.hash)    # faster than path =~ /^\//
  end

  def not_found env
    [
      STATUS__NOT_FOUND,
      {'Content-Type' => "text/plain", "X-Cascade" => "pass"},
      ['Not Found: %s' % env[ENV__PATH_INFO]]
    ]
  end

  def not_implemented implemented
    [
      STATUS__NOT_IMPLEMENTED,
      {"Content-Type" => "text/plain"},
      ["Resource found but it can be accessed only through %s" % implemented]
    ]
  end
  
end
