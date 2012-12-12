class E

  # shorthand for `response.set_cookie` and `response.delete_cookie`.
  # also it allow to make cookies readonly.
  def cookies
    @__e__cookies_proxy ||= Class.new do

      def initialize controller
        @controller, @request, @response =
          controller, controller.request, controller.response
      end

      # set cookie header
      #
      # @param [String, Symbol] key
      # @param [String, Hash] val
      # @return [Boolean]
      def []= key, val
        return if readonly?
        @response.set_cookie key, val
      end

      # get cookie by key
      def [] key
        @request.cookies[key]
      end

      # instruct browser to delete a cookie
      #
      # @param [String, Symbol] key
      # @param [Hash] opts
      # @return [Boolean]
      def delete key, opts ={}
        return if readonly?
        @response.delete_cookie key, opts
      end

      # prohibit further cookies writing
      #
      # @example prohibit writing for all actions
      #    before do
      #      cookies.readonly!
      #    end
      #
      # @example prohibit writing only for :render and :display actions
      #    before :render, :display do
      #      cookies.readonly!
      #    end
      def readonly!
        @readonly = true
      end

      def readonly?
        @readonly
      end

      def method_missing *args
        @request.cookies.send *args
      end
    end.new self
  end

end
