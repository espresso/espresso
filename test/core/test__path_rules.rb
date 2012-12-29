module ECoreTest__PathRules

  class DefaultRules < E
    map :/

    def four____slashes
      "four.slashes"
    end

    def three___slashes
      "three-slashes"
    end

    def two__slashes
      "two/slashes"
    end

  end

  class CustomRules < E
    path_rule "__", "/"
    path_rule "_dot_", "."
    path_rule "_dash_", "-"
    path_rule "_comma_", ","
    path_rule "_obr_", "("
    path_rule "_cbr_", ")"

    def slash__html
      "slash/html"
    end

    def dot_dot_html
      "dot.html"
    end

    def dash_dash_html
      "dash-html"
    end

    def comma_comma_html
      "comma,html"
    end

    def brackets_obr_html_cbr_
      "brackets(html)"
    end

  end

  Spec.new self do
    Test :default_rules do
      app DefaultRules.mount
      map DefaultRules.base_url

      %w[
      four.slashes
      three-slashes
      two/slashes
      ].each do |action|
        get action
        assert(last_response.body) == action
      end

    end

    Test :custom_rules do
      app CustomRules.mount
      map CustomRules.base_url

      %w[
      dot.html
      slash/html
      dash-html
      comma,html
      brackets(html)
      ].each do |action|
        get action
        assert(last_response.body) == action
      end

    end

  end
end

