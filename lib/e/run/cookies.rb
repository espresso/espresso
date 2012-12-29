class E

  # shorthand for `response.set_cookie` and `response.delete_cookie`.
  #
  # @example Setting a cookie
  # cookies['cookie-name'] = 'value'
  #
  # @example Reading a cookie
  # cookies['cookie-name']
  # #=> value
  #
  # @example Setting a cookie with custom options
  # cookies['question_of_the_day'] = {:value => 'who is not who?', :expires => Date.today + 1, :secure => true}
  #
  # @example Deleting a cookie
  # cookies.delete 'cookie-name'
  #
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
        @response.delete_cookie key, opts
      end

      def method_missing *args
        @request.cookies.send *args
      end
    end.new self
  end

end
