require "./context_object"
require "./performance_entry"
require "./performance_entry_list"
require "./performance_resource_timing"

module JS
  module Context
    class Performance < JS::Context::ContextObject
      def initialize
        super("performance")
      end

      def getEntriesByType(entry_type : String) : JS::Context::PerformanceEntryList(JS::Context::PerformanceResourceTiming)
        JS::Context::PerformanceEntryList(JS::Context::PerformanceResourceTiming).new(to_js_ref, "getEntriesByType", entry_type)
      end
    end
  end
end
