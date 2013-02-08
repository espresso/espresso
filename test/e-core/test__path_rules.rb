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
    def check_path_rules(app_to_test, methods)
      app app_to_test.mount
      map app_to_test.base_url
      methods.each do |action|
        get action
        is(action).current_body?
      end
    end

    Testing "default_rules" do
      check_path_rules(DefaultRules,
        %w[
          four.slashes
          three-slashes
          two/slashes
          ]
      )
    end

    Testing "custom_rules" do
      check_path_rules(CustomRules,
        %w[
          dot.html
          slash/html
          dash-html
          comma,html
          brackets(html)
          ]
      )
    end
  end
end

