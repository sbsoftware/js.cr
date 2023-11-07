require "../../spec_helper"

module JS::Module::ImportSpec
  class MyModule < JS::Module
    js_import Application, Controller, from: "/assets/stimulus.js"

    def_to_js do
      window.Stimulus = Application.start._call
    end
  end

  describe "MyModule.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      import { Application, Controller } from "/assets/stimulus.js";
      window.Stimulus = Application.start();
      JS

      MyModule.to_js.should eq(expected)
    end
  end
end
