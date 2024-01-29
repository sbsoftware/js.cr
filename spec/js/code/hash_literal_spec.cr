require "../../spec_helper"

module JS::Code::HashLiteralSpec
  class MyCode < JS::Code
    def_to_js do
      h1 = {} of String => String
      h2 = {"test" => "foo"}
      h3 = {"blah" => 1, "gold" => "digga"}
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var h1;
      var h2;
      var h3;
      h1 = {};
      h2 = {test: "foo"};
      h3 = {blah: 1, gold: "digga"};
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
