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
