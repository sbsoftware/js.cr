module JS
  module Browser
    class Console
      def to_js_ref : String
        "console"
      end

      def log(*args : JS::Browser::MethodCallArgument) : JS::Browser::MethodCall
        build_call("log", *args)
      end

      def info(*args : JS::Browser::MethodCallArgument) : JS::Browser::MethodCall
        build_call("info", *args)
      end

      def warn(*args : JS::Browser::MethodCallArgument) : JS::Browser::MethodCall
        build_call("warn", *args)
      end

      def error(*args : JS::Browser::MethodCallArgument) : JS::Browser::MethodCall
        build_call("error", *args)
      end

      private def build_call(name : String, *args : JS::Browser::MethodCallArgument) : JS::Browser::MethodCall
        JS::Browser::MethodCall.new(to_js_ref).call(name, *args)
      end
    end
  end
end
