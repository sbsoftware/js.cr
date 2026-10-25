require "./console"
require "./document"
require "./navigator"
require "./performance"
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

      def document : JS::Context::Document
        JS::Context::Document.new
      end

      def performance : JS::Context::Performance
        JS::Context::Performance.new
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
