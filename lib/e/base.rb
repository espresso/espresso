class E
  def user
    env[ENV__REMOTE_USER]
  end
  alias user? user

  def app
    self.class.app
  end

  def app_root
    app.root
  end

  # Sugar for redirect (example:  redirect back)
  def back
    request.referer
  end
end


class << E

  def mount *roots, &setup
    return app if app
    locked? && raise(SecurityError, 'App was previously locked, so you can not remount it or change any setup.')
    ::EApp.new.mount self, *roots, &setup
  end
  alias mount!  mount
  alias to_app  mount
  alias to_app! mount

  def call env
    mount.call env
  end

  def run *args
    mount.run *args
  end

  # @api semi-public
  def app= app
    return if locked?
    @app = app
    # overriding @base_url by prepending app's base URL.
    # IMPORTANT: @base_url is a var set by Appetite,
    # so make sure when this name is changed in Appetite it is also changed here
    @base_url = @app.base_url + base_url
  end

  def app
    @app
  end
end