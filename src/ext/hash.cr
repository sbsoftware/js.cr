class Hash(K, V)
  def to_js_ref
    String.build do |io|
      io << "{"
      each_with_index do |(key, value), index|
        io << ", " unless index.zero?
        io << key.to_js_ref << ": " << value.to_js_ref
      end
      io << "}"
    end
  end
end
