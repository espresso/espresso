class E
  
  # kindly borrowed from Sinatra Framework

  # whether or not the status is set to 1xx
  def informational?
    status.between? 100, 199
  end

  # whether or not the status is set to 2xx
  def success?
    status.between? 200, 299
  end

  # whether or not the status is set to 3xx
  def redirect?
    status.between? 300, 399
  end

  # whether or not the status is set to 4xx
  def client_error?
    status.between? 400, 499
  end

  # whether or not the status is set to 5xx
  def server_error?
    status.between? 500, 599
  end

  # whether or not the status is set to 404
  def not_found?
    status == 404
  end
end
