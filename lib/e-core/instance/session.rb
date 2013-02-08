class E
  
  # a simple wrapper around Rack::Session
  def session
    @__e__session_proxy ||= Class.new do

      def initialize session = {}
        @session = session
      end

      def [] key
        @session[key]
      end

      def []= key, val
        @session[key] = val
      end

      def keys
        @session.to_hash.keys
      end

      def values
        @session.to_hash.values
      end

      def delete key
        @session.delete key
      end

      def method_missing *args
        @session.send *args
      end

    end.new env['rack.session']
  end

  # @example
  #    flash[:alert] = 'Item Deleted'
  #    p flash[:alert] #=> "Item Deleted"
  #    p flash[:alert] #=> nil
  def flash
    @__e__flash_proxy ||= Class.new do

      def initialize session = {}
        @session = session
      end

      def []= key, val
        @session[key(key)] = val
      end

      def [] key
        return unless val = @session[key = key(key)]
        @session.delete key
        val
      end

      def key key
        '__e__session__flash__-' << key.to_s
      end
    end.new env['rack.session']
  end
end
