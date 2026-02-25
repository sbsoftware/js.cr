require "./context_object"
require "./element"
require "./node_list"

module JS
  module Context
    class Document < JS::Context::ContextObject
      def initialize
        super("document")
      end

      def querySelector(selector : String) : JS::Context::Element?
        # Keep the selector result typed as optional even though wrapper generation always emits a reference.
        JS::Context::Element.new(to_js_ref, "querySelector", selector).as(JS::Context::Element?)
      end

      def querySelectorAll(selector : String) : JS::Context::NodeList
        JS::Context::NodeList.new(to_js_ref, "querySelectorAll", selector)
      end
    end
  end
end
