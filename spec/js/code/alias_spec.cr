require "../../spec_helper"

module JS::Code::AliasSpec
  class MyJQueryCode < JS::Code
    js_alias "jQuery", "$"

    def_to_js do
      jQuery("div").each do |div|
        div.classList.toggle("some-class")
      end
    end
  end

  describe "MyJQueryCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      $("div").each(function(div) {
        div.classList.toggle("some-class");
      });
      JS

      MyJQueryCode.to_js.should eq(expected)
    end
  end
end
