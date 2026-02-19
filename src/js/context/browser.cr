require "./console"
require "./navigator"
require "./window"

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
        window.{{call}}
      end
    end

    def self.default : JS::Context::Browser
      JS::Context::Browser.new
    end
  end
end
