module EspressoFrameworkConstants

  HTTP__DEFAULT_SERVER = :WEBrick
  HTTP__DEFAULT_PORT   = 5252

  HTTP__REQUEST_METHODS = %w[GET POST PUT HEAD DELETE OPTIONS PATCH].freeze

  E__PATH_RULES = {
    '____' => '.'.freeze,
    '___'  => '-'.freeze,
    '__'   => '/'.freeze,
  }.freeze

  E__INDEX_ROUTE = 'index'.freeze

  CONTENT_TYPE__DEFAULT      = 'text/html'.freeze
  CONTENT_TYPE__EVENT_STREAM = 'text/event-stream'.freeze

  RESPOND_TO__PARAMETERS = method(methods.first).respond_to?(:parameters)
  RESPOND_TO__SOURCE_LOCATION = proc {}.respond_to?(:source_location)

  STATUS__OK = 200
  STATUS__PERMANENT_REDIRECT = 301
  STATUS__REDIRECT = 302
  STATUS__PROTECTED = 401
  STATUS__NOT_FOUND = 404
  STATUS__SERVER_ERROR = 500

  ENV__SCRIPT_NAME    = 'SCRIPT_NAME'.freeze
  ENV__REQUEST_METHOD = 'REQUEST_METHOD'.freeze
  ENV__PATH_INFO      = 'PATH_INFO'.freeze
  ENV__HTTP_ACCEPT    = 'HTTP_ACCEPT'.freeze
  ENV__QUERY_STRING   = 'QUERY_STRING'.freeze
  ENV__REMOTE_USER    = 'REMOTE_USER'.freeze
  ENV__HTTP_X_FORWARDED_HOST    = 'HTTP_X_FORWARDED_HOST'.freeze
  ENV__HTTP_IF_NONE_MATCH       = 'HTTP_IF_NONE_MATCH'.freeze
  ENV__HTTP_IF_MODIFIED_SINCE   = 'HTTP_IF_MODIFIED_SINCE'.freeze
  ENV__HTTP_IF_UNMODIFIED_SINCE = 'HTTP_IF_UNMODIFIED_SINCE'.freeze

  HEADER__CONTENT_TYPE  = 'Content-Type'.freeze
  HEADER__LAST_MODIFIED = 'Last-Modified'.freeze
  HEADER__CACHE_CONTROL = 'Cache-Control'.freeze
  HEADER__EXPIRES       = 'Expires'.freeze
  HEADER__CONTENT_DISPOSITION = 'Content-Disposition'.freeze

  RACK__WEBSOCKET = 'rack.websocket'.freeze
end
