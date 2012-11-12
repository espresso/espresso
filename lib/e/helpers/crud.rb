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
  # @option path_or_opts [Integer] :pkey
  #   item's primary key(default :id) to be returned when item created /updated.
  #   if no pkey given and item does not respond to :id, the item itself returned.
  # @option path_or_opts [Integer] :halt_on_errors
  #   if created/updated item contain errors,
  #   halt processing unconditionally, even if proc given.
  #   if this option is false(default) and a proc given,
  #   it will pass item object and extracted errors to proc rather than halt.
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
    
    proc_accept_object, proc_accept_errors = nil
    if proc
      proc_accept_object = proc.arity > 0
      proc_accept_errors = proc.arity > 1
    end

    presenter = lambda do |controller_instance, obj|

      join_with = opts[:join_with] || ', '
      halt_with = opts[:halt_with] || 500
      pkey      = opts[:pkey]      || :id

      # extracting errors, if any
      errors = nil
      if obj.respond_to?(:errors) && (raw_errors = obj.errors) &&
        raw_errors.respond_to?(:size) && raw_errors.size > 0

        if raw_errors.respond_to?(:join)
          errors = raw_errors
        else
          if raw_errors.respond_to?(:each_pair) # seems error is a Hash
            # some objects may respond to `each_pair` but not respond to `inject`,
            # so using trivial looping to extract error messages.
            errors = []
            raw_errors.each_pair do |k,v|
              # usually DataMapper returns erros in the following format:
              # { :property => ['error 1', 'error 2'] }
              # flatten is there just in case we get nested arrays.
              error = v.is_a?(Array) ? v.flatten.join(join_with) : v.to_s
              errors << '%s: %s' % [k, error]
            end
          elsif raw_errors.respond_to?(:to_a) # not Array nor Hash, but convertible to Array
            # converting error to Array and joining
            errors = raw_errors.to_a
          else
            # otherwise simply force converting the error to String
            errors = [raw_errors.inspect]
          end
        end
      end
      errors && errors = controller_instance.escape_html(errors.join(join_with))
      
      if proc
        if errors && opts[:halt_on_errors]
          controller_instance.halt halt_with, errors
        end
        proc_args = []
        proc_args = [obj] if proc_accept_object
        proc_args = [obj, errors] if proc_accept_errors
        controller_instance.instance_exec(*proc_args, &proc)
      else
        if errors
          # no proc given, so halting when some errors occurring
          controller_instance.halt halt_with, errors
        else
          # no proc given and no errors detected,
          # so extracting and returning object's pkey.
          # if no pkey given and object does not respond to :id nor to :[],
          # returning object as is.
          if obj.respond_to?(:[]) && obj.respond_to?(:has_key?)
            obj.has_key?(pkey) ? obj[pkey] : obj
          elsif obj.respond_to?(pkey)
            obj.send(pkey)
          else
            obj
          end
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
