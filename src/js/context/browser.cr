require "./console"
require "./navigator"
require "./window"

module JS
  module Context
    class Browser
      def console : JS::Context::Console
        JS::Context::Console.new
      end

      # Strict mode probes receiverless identifiers as `JS::Context.default.<name>`
      # before JS emission; these no-arg entrypoints let the compiler validate
      # window-backed APIs that require runtime arguments.
      def setTimeout : JS::Context::Window
        window
      end

      def clearTimeout : JS::Context::Window
        window
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
