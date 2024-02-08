require "../../spec_helper"

module JS::Code::ArrayLiteralSpec
  class MyCode < JS::Code
    def_to_js do
      empty_arr = [] of String
      arr1 = ["foo", "bar", "baz"]
      arr2 = [1, 2, 3]
      arr3 = ["blah", 4]
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var empty_arr;
      var arr1;
      var arr2;
      var arr3;
      empty_arr = [];
      arr1 = ["foo", "bar", "baz"];
      arr2 = [1, 2, 3];
      arr3 = ["blah", 4];
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
