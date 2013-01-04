# this file contains aliases
class E
  alias rq request
  alias rs response
  alias auth basic_auth
  alias baseurl base_url
  alias format? format
  alias canonical? canonical
  alias user? user

  alias fail!  fail
  alias quit   fail
  alias quit!  fail
  alias error  fail
  alias error! fail
  alias deferred_redirect delayed_redirect
end

class << E
  alias to_app  mount
  alias to_app! mount
  alias urlmap url_map
  alias baseurl base_url
  alias on    before
  alias setup before
end

class EApp
  alias app_root root
  alias auth basic_auth
  alias setup_controllers global_setup
  alias setup global_setup
  alias rewrite_rule rewrite
  alias urlmap url_map
  alias to_app app
end

class EspressoFrameworkRequest
  alias accept? preferred_type
  alias secure? ssl?
end