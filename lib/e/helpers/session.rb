class E

  # a simple wrapper around Rack::Session
  def session
    @__e__session_proxy ||= Class.new do
      attr_reader :session

      def initialize session = {}
        @session = session
      end

      def [] key
        session[key]
      end

      def []= key, val
        return if readonly?
        session[key] = val
      end

      def delete key
        return if readonly?
        session.delete key
      end

      # makes sessions readonly
      #
      # @example prohibit writing for all actions
      #    before do
      #      session.readonly!
      #    end
      #
      # @example prohibit writing only for :render and :display actions
      #    before :render, :display do
      #      session.readonly!
      #    end
      def readonly!
        @readonly = true
      end

      def readonly?
        @readonly
      end

      def method_missing *args
        session.send *args
      end

    end.new env['rack.session']
  end

  # @example
  #    flash[:alert] = 'Item Deleted'
  #    p flash[:alert] #=> "Item Deleted"
  #    p flash[:alert] #=> nil
  #
  # @note if sessions are confined, flash will not work,
  #       so do not confine sessions for all actions,
  #       confine them only for actions really need this.
  def flash
    @__e__flash_proxy ||= Class.new do
      attr_reader :session

      def initialize session = {}
        @session = session
      end

      def []= key, val
        session[key(key)] = val
      end

      def [] key
        return unless val = session[key = key(key)]
        session.delete key
        val
      end

      def key key
        '__e__session__flash__-' << key.to_s
      end
    end.new env['rack.session']
  end

end
