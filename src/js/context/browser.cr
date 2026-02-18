require "./console"
require "./navigator"
require "./window"
require "./window_member"

module JS
  module Context
    class Browser
      def console : JS::Context::Console
        JS::Context::Console.new
      end

      def window : JS::Context::Window
        JS::Context::Window.new
      end

      def navigator : JS::Context::Navigator
        JS::Context::Navigator.new
      end

      macro method_missing(call)
        {% window_type = parse_type("JS::Context::Window").resolve %}
        {% if window_type && window_type.is_a?(TypeNode) && window_type.has_method?(call.name) %}
          {% if call.args.empty? && call.named_args.is_a?(Nop) && !call.block %}
            JS::Context::WindowMember.new({{call.name.stringify}})
          {% else %}
            window.{{call}}
          {% end %}
        {% else %}
          {{call.raise "undefined method '#{call.name}' for JS::Context::Browser"}}
        {% end %}
      end
    end

    def self.default : JS::Context::Browser
      JS::Context::Browser.new
    end
  end
end
