require "spec"
require "../src/js"

class String
  def squish
    split(/\n\s*/).join
  end
end
