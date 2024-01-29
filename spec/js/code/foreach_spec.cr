require "../../spec_helper"

module JS::Code::ForeachSpec
  class MyJs < JS::Code
    def_to_js do
      arr = ["this", "is", "sparta"]
      arr.forEach do |item|
        console.log(item)
      end
    end
  end

  describe "MyJs.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var arr;
      arr = ["this", "is", "sparta"];
      arr.forEach(function(item) {
        console.log(item);
      });
      JS

      MyJs.to_js.should eq(expected)
    end
  end
end
