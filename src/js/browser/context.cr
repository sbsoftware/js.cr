module JS
  module Browser
    class Context
      def console : JS::Browser::Console
        JS::Browser::Console.new
      end
    end

    def self.default_context : JS::Browser::Context
      JS::Browser::Context.new
    end
  end
end
