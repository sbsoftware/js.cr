require "./context_object"
require "./undefined"

module JS
  module Browser
    class Console < JS::Browser::ContextObject
      def initialize
        super("console")
      end

      def log(*args : JS::Browser::CallArgument) : JS::Browser::Undefined
        build_call("log", *args)
      end

      def info(*args : JS::Browser::CallArgument) : JS::Browser::Undefined
        build_call("info", *args)
      end

      def warn(*args : JS::Browser::CallArgument) : JS::Browser::Undefined
        build_call("warn", *args)
      end

      def error(*args : JS::Browser::CallArgument) : JS::Browser::Undefined
        build_call("error", *args)
      end

      private def build_call(name : String, *args : JS::Browser::CallArgument) : JS::Browser::Undefined
        JS::Browser::Undefined.new(to_js_ref, name, *args)
      end
    end
  end
end
