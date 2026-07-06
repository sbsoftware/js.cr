require "./context_object"
require "./event_target"
require "./undefined"

module JS
  module Context
    class DOMStringValue < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end
    end

    class AttributeValue < JS::Context::ContextObject
      def initialize(preceding_call_chain : String, method_name : String, *args)
        super(preceding_call_chain, method_name, *args)
      end
    end

    class ClassListToggleResult < JS::Context::ContextObject
    end

    class DOMTokenList < JS::Context::ContextObject
      def initialize(to_js_ref : String)
        super(to_js_ref)
      end

      def add(token) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "add", token)
      end

      def remove(token) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "remove", token)
      end

      def toggle(token, force = nil) : JS::Context::ClassListToggleResult
        if force.nil?
          JS::Context::ClassListToggleResult.new(to_js_ref, "toggle", token)
        else
          JS::Context::ClassListToggleResult.new(to_js_ref, "toggle", token, force)
        end
      end
    end

    class Element < JS::Context::EventTarget
      def innerHTML : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.innerHTML")
      end

      def textContent : JS::Context::DOMStringValue
        JS::Context::DOMStringValue.new("#{to_js_ref}.textContent")
      end

      def classList : JS::Context::DOMTokenList
        JS::Context::DOMTokenList.new("#{to_js_ref}.classList")
      end

      def setAttribute(name, value) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "setAttribute", name, value)
      end

      def getAttribute(name) : JS::Context::AttributeValue
        JS::Context::AttributeValue.new(to_js_ref, "getAttribute", name)
      end

      def removeAttribute(name) : JS::Context::Undefined
        JS::Context::Undefined.new(to_js_ref, "removeAttribute", name)
      end

      def appendChild(child) : JS::Context::Element
        JS::Context::Element.new(to_js_ref, "appendChild", child)
      end

      def removeChild(child) : JS::Context::Element
        JS::Context::Element.new(to_js_ref, "removeChild", child)
      end
    end
  end
end
