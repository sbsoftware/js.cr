require "./console"

module JS
  module Context
    class Browser
      def console : JS::Context::Console
        JS::Context::Console.new
      end
    end

    def self.default : JS::Context::Browser
      JS::Context::Browser.new
    end
  end
end
