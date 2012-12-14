class << E
  # @example restricting all actions using Basic authorization:
  #    auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #
  # @example restricting only :edit action:
  #    setup :edit do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @example restricting only :edit and :delete actions:
  #    setup :edit, :delete do
  #      auth { |user, pass| ['user', 'pass'] == [user, pass] }
  #    end
  #
  # @params [Hash] opts
  # @option opts [String] :realm
  #   default - AccessRestricted
  # @param [Proc] proc
  def basic_auth opts = {}, &proc
    add_restriction true, :basic, opts, &proc
  end
  alias auth basic_auth

  def basic_auth! opts = {}, &proc
    add_restriction false, :basic, opts, &proc
  end
  alias auth! basic_auth!

  # @example digest auth - hashed passwords:
  #    # hash the password somewhere in irb:
  #    # ::Digest::MD5.hexdigest 'user:AccessRestricted:somePassword'
  #    #=> 9d77d54decc22cdcfb670b7b79ee0ef0
  #
  #    digest_auth :passwords_hashed => true, :realm => 'AccessRestricted' do |user|
  #      {'admin' => '9d77d54decc22cdcfb670b7b79ee0ef0'}[user]
  #    end
  #
  # @example digest auth - plain password
  #    digest_auth do |user|
  #      {'admin' => 'password'}[user]
  #    end
  #
  # @params [Hash] opts
  # @option opts [String] :realm
  #   default - AccessRestricted
  # @option opts [String] :opaque
  #   default - same as realm
  # @option opts [Boolean] :passwords_hashed
  #   default - false
  # @param [Proc] proc
  def digest_auth opts = {}, &proc
    add_restriction true, :digest, opts, &proc
  end

  def digest_auth! opts = {}, &proc
    add_restriction false, :digest, opts, &proc
  end

  def restrictions? action = nil
    return unless @restrictions
    action ?
      @restrictions[action] || @restrictions[:*] :
      @restrictions
  end

  private

  def add_restriction keep_existing, type, opts = {}, &proc
    return if locked? || proc.nil?
    @restrictions ||= {}
    args = []
    case type
      when :basic
        cls = ::Rack::Auth::Basic
        args << (opts[:realm] || 'AccessRestricted')
      when :digest
        cls = ::Rack::Auth::Digest::MD5
        opts[:realm]  ||= 'AccessRestricted'
        opts[:opaque] ||= opts[:realm]
        args = [opts]
      else
        raise 'wrong auth type: %s' % type.inspect
    end
    setup__actions.each do |a|
      next if @restrictions[a] && keep_existing
      @restrictions[a] = [cls, args, proc]
    end
  end
end

class E
  def user
    env[ENV__REMOTE_USER]
  end
  alias user? user
end
