require "./context_object"

module JS
  module Context
    class Callback < JS::Context::ContextObject
      def initialize(name : String)
        super(name)
      end
    end
  end
end
