require "../../spec_helper"

class SomeRootNamespaceClass
  def self.to_js_ref
    "ROOT".dump
  end
end

module SomeOtherModule
  class OtherClass
    def self.to_js_ref
      "other-module-other-class".dump
    end
  end
end

module JS::Code::ToJsRefSpec
  class OtherClass
    def self.to_js_ref
      "ROAAARR".dump
    end
  end

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
      console.log(OtherClass)
      console.log(SomeRootNamespaceClass)
      console.log(::SomeRootNamespaceClass)
      console.log(SomeOtherModule::OtherClass)

      class_name = OtherClass
      console.log(class_name)
    end
  end

  describe "MyCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var class_name;

      if (43 < 100) {
        console.log("blah");
      }

      console.log(new Date(43).toString());
      console.log("ROAAARR");
      console.log("ROOT");
      console.log("ROOT");
      console.log("other-module-other-class");

      class_name = "ROAAARR";
      console.log(class_name);
      JS

      MyCode.to_js.should eq(expected)
    end
  end
end
