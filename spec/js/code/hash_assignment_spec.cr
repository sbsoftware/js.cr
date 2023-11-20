require "../../spec_helper"

module JS::Code::HashAssignmentSpec
  class MyCode < JS::Code
    def_to_js do
      my_arr = Uint8Array.new(20)
      my_arr[7] = 14
      console.log(my_arr[7])
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var my_arr = new Uint8Array(20);
      my_arr[7] = 14;
      console.log(my_arr[7]);
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
