require "../../spec_helper"

module JS::File::VariableAssignmentSpec
  class MyFile < JS::File
    js_function :func do |event|
      t = event.target
      console.log(t)
    end

    def_to_js do
      event1 = Event.new
      func(event1)
    end
  end

  describe "MyFile.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      function func(event) {
        var t;
        t = event.target;
        console.log(t);
      }
      var event1;
      event1 = new Event();
      func(event1);
      JS

      MyFile.to_js.should eq(expected)
    end
  end
end
