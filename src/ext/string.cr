class String
  def self.to_js_ref
    "String"
  end

  def to_js_ref
    self.dump
  end
end
