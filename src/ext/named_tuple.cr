struct NamedTuple
  def self.to_js_ref
    "Object"
  end

  def to_js_ref
    String.build do |str|
      str << "{"
      self.map do |key, value|
        "#{key}: #{value.to_js_ref}"
      end.join(str, ", ")
      str << "}"
    end
  end
end
