
class Object
  # borrowed from Rails
  # http://api.rubyonrails.org/classes/Object.html#method-i-presence
  begin
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end

    def present?
      !blank?
    end

    def presence
      self if present?
    end
  end
end