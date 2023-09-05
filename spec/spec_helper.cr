require "spec"
require "../src/*"

class String
  def squish
    split(/\n\s*/).join
  end
end
