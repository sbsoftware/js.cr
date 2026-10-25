require "./context_object"

module JS
  module Context
    # The entry type carries block-item information while JS emission follows the same generic forEach path as NodeList.
    class PerformanceEntryList(T) < JS::Context::ContextObject
    end
  end
end
