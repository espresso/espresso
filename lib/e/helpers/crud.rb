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
      :get    => opts.fetch(:get, :get),
      :post   => opts.fetch(:post, :create),
      :put    => opts.fetch(:put, :update),
      :patch  => opts.fetch(:patch, :update),
      :delete => opts.fetch(:delete, :delete),
    }
    
    proc_accept_object, proc_accept_errors = nil
    if proc
      proc_accept_object = proc.arity > 0
      proc_accept_errors = proc.arity > 1
    end

    pkey      = opts[:pkey]      || :id
    join_with = opts[:join_with] || ', '
    halt_with = opts[:halt_with] || 500

    presenter = lambda do |controller_instance, obj, err|

      # extracting errors, if any
      errors = nil
      if err || (obj.respond_to?(:errors) && (err = obj.errors) &&
        err.respond_to?(:size) && err.size > 0)

        if err.respond_to?(:join)
          errors = err
        else
          if err.respond_to?(:each_pair) # seems error is a Hash
            # some objects may respond to `each_pair` but not respond to `inject`,
            # so using trivial looping to extract error messages.
            errors = []
            err.each_pair do |k,v|
              # usually DataMapper returns erros in the following format:
              # { :property => ['error 1', 'error 2'] }
              # flatten is there just in case we get nested arrays.
              error = v.is_a?(Array) ? v.flatten.join(join_with) : v.to_s
              errors << '%s: %s' % [k, error]
            end
          elsif err.respond_to?(:to_a) # not Array nor Hash, but convertible to Array
            # converting error to Array and joining
            errors = err.to_a
          elsif err.is_a?(String)
            errors = [err]
          else
            errors = [err.inspect]
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
      obj, err = nil
      begin
        obj = resource.send(resource_method[:get], id) ||
          controller_instance.halt(404, 'object with ID %s not found' % controller_instance.escape_html(id))
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    create_object = lambda do |controller_instance|
      obj, err = nil
      begin
        data = controller_instance.params.reject { |k,v| opts[:exclude].include?(k) }
        obj  = resource.send(resource_method[:post], data)
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    update_object = lambda do |controller_instance, request_method, id|
      obj, err = nil
      begin
        obj, err = fetch_object.call(controller_instance, id)
        unless err
          data = controller_instance.params.reject { |k,v| opts[:exclude].include?(k) }
          obj.send(resource_method[request_method], data)
        end
      rescue => e
        err = e.message
      end
      [obj, err]
    end

    # if resource respond to #delete(or whatever set in options for delete),
    # sending #delete to resource, with given id as 1st param.
    # otherwise, fetching object by given id and sending #delete on it.
    #
    # @return [String] empty string
    delete_object = lambda do |id|
      err = nil
      begin
        meth = resource_method[:delete]
        if resource.respond_to?(meth)
          resource.send(meth, id)
        else
          obj, err = fetch_object.call(self, id)
          unless err
            if obj.respond_to?(meth)
              obj.send meth
            elsif obj.respond_to?(:delete!)
              obj.send :delete!
            elsif obj.respond_to?(:destroy)
              obj.send :destroy
            elsif obj.respond_to?(:destroy!)
              obj.send :destroy!
            else
              err = 'Given object does not respond to any of #%s' % [
                escape_html(meth), :delete!, :destroy, :destroy!
              ].uniq.join(" #")
            end
          end
        end
      rescue => e
        err = e.message
      end
      [nil, err]
    end

    options = lambda do |controller_instance|
      ::AppetiteConstants::REQUEST_METHODS.map do |request_method|
        if restriction = restrictions?((action % request_method.downcase).to_sym)
          auth_class, auth_args, auth_proc = restriction
          auth_class.new(proc {}, *auth_args, &auth_proc).call(controller_instance.env) ? nil : request_method
        else
          request_method
        end
      end.compact.join(', ')
    end

    self.class_exec do

      define_method action % :get do |id|
        presenter.call self, *fetch_object.call(self, id)
      end

      define_method action % :head do |id|
        presenter.call self, *fetch_object.call(self, id)
      end

      define_method action % :post do
        presenter.call self, *create_object.call(self)
      end

      [:put, :patch].each do |request_method|
        define_method action % request_method do |id|
          presenter.call self, *update_object.call(self, request_method, id)
        end
      end

      define_method action % :delete do |id|
        presenter.call self, *delete_object.call(id)
      end

      define_method action % :options do
        options.call self
      end
    end

  end

  alias crudify crud

end
