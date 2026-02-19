require "./context_object"
require "./undefined"

module JS
  module Context
    alias NodeListForEachCallback = String | JS::Context::ContextObject

    class NodeList < JS::Context::ContextObject
      def forEach(callback : JS::Context::NodeListForEachCallback) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "forEach", callback)
      end
    end
  end
end
