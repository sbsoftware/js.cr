require "./context_object"
require "./undefined"

module JS
  module Context
    class Console < JS::Context::ContextObject
      def initialize
        super("console")
      end

      def log(*args : JS::Context::CallArgument) : JS::Context::Undefined
        build_call("log", *args)
      end

      def info(*args : JS::Context::CallArgument) : JS::Context::Undefined
        build_call("info", *args)
      end

      def warn(*args : JS::Context::CallArgument) : JS::Context::Undefined
        build_call("warn", *args)
      end

      def error(*args : JS::Context::CallArgument) : JS::Context::Undefined
        build_call("error", *args)
      end

      private def build_call(name : String, *args : JS::Context::CallArgument) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, name, *args)
      end
    end
  end
end
