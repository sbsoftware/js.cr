require "../../spec_helper"

module JS::Module::AliasSpec
  class MyUnderscoreModule < JS::Module
    js_alias "underscore", "_"

    def_to_js do
      underscore("div").each do |div|
        div.classList.toggle("some-class")
      end
    end
  end

  describe "MyUnderscoreModule.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      _("div").each(function(div) {
        div.classList.toggle("some-class");
      });
      JS

      MyUnderscoreModule.to_js.should eq(expected)
    end
  end
end
