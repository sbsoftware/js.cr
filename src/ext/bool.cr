struct Bool
  def self.to_js_ref
    "Boolean"
  end

  def to_js_ref
    self ? "true" : "false"
  end
end
