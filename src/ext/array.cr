class Array(T)
  def self.to_js_ref
    "Array"
  end

  def to_js_ref
    "[#{self.map(&.to_js_ref).join(", ")}]"
  end
end
