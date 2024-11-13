class Array(T)
  def to_js_ref
    "[#{self.map(&.to_js_ref).join(", ")}]"
  end
end
