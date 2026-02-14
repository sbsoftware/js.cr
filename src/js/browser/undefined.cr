require "./context_object"

module JS
  module Browser
    class Undefined < JS::Browser::ContextObject
      def initialize(preceding_call_chain : String, method_name : String, *args : JS::Browser::CallArgument)
        super(preceding_call_chain, method_name, *args)
      end
    end
  end
end
