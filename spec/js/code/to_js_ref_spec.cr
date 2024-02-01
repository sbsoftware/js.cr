require "../../spec_helper"

module JS::Code::ToJsRefSpec
  class MyCode < JS::Code
    IMPORTANT_CONTENT_FROM_CRYSTAL = "blah"

    def self.important_number_from_crystal
      43 # dude
    end

    def_to_js do
      if important_number_from_crystal.to_js_ref < 100
        console.log(IMPORTANT_CONTENT_FROM_CRYSTAL.to_js_ref)
      end

      console.log(Date.new(important_number_from_crystal.to_js_ref).toString._call)
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      if (43 < 100) {
        console.log("blah");
      }

      console.log(new Date(43).toString());
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
