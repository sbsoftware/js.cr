require "../../spec_helper"

module JS::Module::StimulusSpec
  class MyModule < JS::Module
    js_import Application, Controller, from: "/assets/stimulus.js"

    js_class MyController do
      js_extends Controller

      js_method :connect do
        console.log("connected!")
      end
    end

    def_to_js do
      window.Stimulus = Application.start._call

      Stimulus.register("my", MyController)
    end
  end

  describe "MyModule.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      import { Application, Controller } from "/assets/stimulus.js";
      class MyController extends Controller {
        connect() {
          console.log("connected!");
        }
      }

      window.Stimulus = Application.start();
      Stimulus.register("my", MyController);
      JS

      MyModule.to_js.should eq(expected)
    end
  end
end
