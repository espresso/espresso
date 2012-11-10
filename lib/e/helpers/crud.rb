class << E

  #
  # automatically creates POST/PUT/DELETE actions
  # and map them to corresponding methods of given resource,
  # so sending a POST request to the controller
  # resulting in creating new object of given resource.
  #
  # PUT/PATCH requests will update objects by given id.
  # DELETE requests will delete objects by given id.
  #
  # @params [Array] path_or_opts
  # @option path_or_opts [String || Array] :exclude
  #   sometimes forms sending extra params. exclude them using :exclude option
  # @option path_or_opts [Integer] :halt_with
  #   when resource are not created/updated because of errors,
  #   Espresso will halt operation with 500 error status code.
  #   use :halt_with option to set a custom error status code.
  # @option path_or_opts [String] :join_with
  #   if resource thrown some errors, Espresso will join them using a coma.
  #   use :join_with option to set a custom glue.
  #
  def crud resource, *path_or_opts, &proc
    opts = path_or_opts.last.is_a?(Hash) ? path_or_opts.pop : {}
    if opts[:exclude]
      opts[:exclude] = [ opts[:exclude] ] unless opts[:exclude].is_a?(Array)
    else
      opts[:exclude] = []
    end
    path = path_or_opts.first
    action = '%s_' << (path || :index).to_s
    resource_method = {
      :get => opts.fetch(:get, :get),
      :post => opts.fetch(:post, :create),
      :put => opts.fetch(:put, :update),
      :patch => opts.fetch(:patch, :update),
      :delete => opts.fetch(:delete, :delete),
    }
    presenter = lambda do |controller_instance, obj|
      if proc 
        controller_instance.instance_exec(obj, &proc)
      else
        if obj.respond_to?(:errors) && (errors = obj.errors) &&
          errors.respond_to?(:size) && errors.size > 0

          join_with = opts[:join_with] || ', '

          if errors.respond_to?(:join)
            # seems error is an Array
            error_message = errors.join(join_with)
          else
            if errors.respond_to?(:each_pair) # seems error is a Hash
              # some objects may respond to `each_pair` but not to `inject`,
              # so using trivial looping to extract error messages
              error_message = []
              errors.each_pair { |*e| error_message << '%s: %s' % e.flatten }
              error_message = error_message.join(join_with)
            elsif errors.respond_to?(:to_a) # convertible to Array
              # converting error to Array and joining
              error_message = errors.to_a.join(join_with)
            else
              # otherwise simply force converting the error to String
              error_message = errors.inspect
            end
          end
          controller_instance.halt opts[:halt_with] || 500, error_message
        else
          # no proc given and no errors detected, so returning the object as is
          obj
        end
      end
    end
    fetch_object = lambda do |controller_instance, id|
      resource.send(resource_method[:get], id) ||
          controller_instance.halt(404, 'object with ID %s not found' % controller_instance.escape_html(id))
    end
    update_object = lambda do |controller_instance, request_method, id|
      object = fetch_object.call(controller_instance, id)
      object.send(resource_method[request_method], controller_instance.params.reject { |k,v| opts[:exclude].include?(k) })
      presenter.call controller_instance, object
    end
    self.class_exec do

      define_method action % :get do |id|
        presenter.call self, fetch_object.call(self, id)
      end

      define_method action % :head do |id|
        presenter.call self, fetch_object.call(self, id)
      end

      define_method action % :post do
        presenter.call self, resource.send(resource_method[:post], params.reject { |k,v| opts[:exclude].include?(k) })
      end

      define_method action % :put do |id|
        update_object.call self, :put, id
      end

      define_method action % :patch do |id|
        update_object.call self, :patch, id
      end

      # if resource respond to #delete(or whatever set in options for delete),
      # sending #delete to resource, with given id as 1st param.
      # otherwise, fetching object by given id and sending #delete on it.
      #
      # @return [String] empty string
      define_method action % :delete do |id|
        meth = resource_method[:delete]
        if resource.respond_to?(meth)
          resource.send(meth, id)
        elsif object = fetch_object.call(self, id)
          if object.respond_to?(meth)
            object.send meth
          elsif object.respond_to?(:delete!)
            object.send :delete!
          elsif object.respond_to?(:destroy)
            object.send :destroy
          elsif object.respond_to?(:destroy!)
            object.send :destroy!
          else
            halt 500, 'Given object does not respond to any of #%s' % [
              meth, :delete!, :destroy, :destroy!
            ].uniq.join(" #")
          end
        end
        ''
      end

      define_method action % :options do
        ::AppetiteConstants::REQUEST_METHODS.map do |request_method|
          if restriction = self.class.restrictions?((action % request_method.downcase).to_sym)
            auth_class, auth_args, auth_proc = restriction
            auth_class.new(proc {}, *auth_args, &auth_proc).call(env) ? nil : request_method
          else
            request_method
          end
        end.compact.join(', ')
      end

    end

  end

  alias crudify crud

end
