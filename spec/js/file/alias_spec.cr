require "../../spec_helper"

module JS::File::AliasSpec
  class MyAliasFile < JS::File
    js_alias "jq", "$"

    def_to_js do
      jq("div").addClass("my-class")
    end
  end

  describe "MyAliasFile.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      $("div").addClass("my-class");
      JS

      MyAliasFile.to_js.should eq(expected)
    end
  end
end
