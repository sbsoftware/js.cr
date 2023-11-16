require "../../spec_helper"

module JS::Code::MacroSpec
  class MyJs < JS::Code
    def_to_js do
      {% if true %}
        console.log("This is in it")
      {% end %}

      {% for str in ["This", "Is", "Sparta"] %}
        console.log({{str}})
      {% end %}
    end
  end

  describe "MyJs.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      console.log("This is in it");
      console.log("This");
      console.log("Is");
      console.log("Sparta");
      JS

      MyJs.to_js.should eq(expected)
    end
  end
end
