require "./context_object"

module JS
  module Context
    class Promise < JS::Context::ContextObject
      def self.to_js_ref : String
        "Promise"
      end

      def self.all(iterable) : JS::Context::Promise
        new(to_js_ref, "all", iterable)
      end

      def then(callback) : JS::Context::Promise
        JS::Context::Promise.new(to_js_ref, "then", callback)
      end

      def catch(callback) : JS::Context::Promise
        JS::Context::Promise.new(to_js_ref, "catch", callback)
      end

      def finally(callback) : JS::Context::Promise
        JS::Context::Promise.new(to_js_ref, "finally", callback)
      end
    end
  end
end
