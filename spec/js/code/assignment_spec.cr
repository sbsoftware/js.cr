require "../../spec_helper"

module JS::Code::AssignmentSpec
  class MyCode < JS::Code
    def_to_js do
      my_var = 1
      my_var += 1
    end

    describe "MyCode.to_js" do
      it "return the correct JS code" do
        expected = <<-JS.squish
        var my_var;
        my_var = 1;
        my_var = my_var + 1;
        JS

        MyCode.to_js.should eq(expected)
      end
    end
  end
end
