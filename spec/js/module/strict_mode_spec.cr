require "../../spec_helper"

module JS::Module::StrictModeSpec
  class StrictModule < JS::Module
    js_import Controller, from: "/assets/stimulus.js"
    js_alias "doc", "document"

    def_to_js strict: true do
      title = doc.querySelector("title")
      console.log(title)
    end
  end

  describe "StrictModule.to_js" do
    it "supports strict mode opt-in" do
      expected = <<-JS.squish
      import { Controller } from "/assets/stimulus.js";
      var title;
      title = document.querySelector("title");
      console.log(title);
      JS

      StrictModule.to_js.should eq(expected)
    end
  end
end
