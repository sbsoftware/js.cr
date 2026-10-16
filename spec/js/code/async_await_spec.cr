require "../../spec_helper"

module JS::Code::AsyncAwaitSpec
  class AsyncFunctionCode < JS::Code
    def_to_js do
      handler = async do |event|
        console.log(event)
      end
    end
  end

  class AwaitCode < JS::Code
    def_to_js do
      response = await(fetch("/data"))
    end
  end

  class StrictPromiseCompositionCode < JS::Code
    def_to_js strict: true do
      urls = ["/first", "/second"]
      responses = await(Promise.all(urls.map(async do |url|
        return await(fetch(url))
      end)))
      responses.then do |response|
        console.log(response)
      end.catch(async do |error|
        console.log(error)
      end).finally do
        console.log("complete")
      end
    end
  end

  describe "AsyncFunctionCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var handler;
      handler = async function(event) {
        console.log(event);
      };
      JS

      AsyncFunctionCode.to_js.should eq(expected)
    end
  end

  describe "AwaitCode.to_js" do
    it "should return the correct JS code" do
      expected = <<-JS.squish
      var response;
      response = await fetch("/data");
      JS

      AwaitCode.to_js.should eq(expected)
    end
  end

  describe "StrictPromiseCompositionCode.to_js" do
    it "composes Promise.all with async collection and promise callbacks in strict mode" do
      expected = <<-JS.squish
      var urls;
      var responses;
      urls = ["/first", "/second"];
      responses = await Promise.all(urls.map(async function(url) {
        return await fetch(url);
      }));
      responses.then(function(response) {
        console.log(response);
      }).catch(async function(error) {
        console.log(error);
      }).finally(function() {
        console.log("complete");
      });
      JS

      StrictPromiseCompositionCode.to_js.should eq(expected)
    end
  end

  describe JS::Context::Promise do
    it "builds typed Promise call chains" do
      callback = JS::Context::Undefined.new("", "callback")
      promises = JS::Context::Undefined.new("", "promises")

      JS::Context::Promise.all(promises).then(callback).catch(callback).finally(callback).to_js_ref.should eq("Promise.all(promises).then(callback).catch(callback).finally(callback)")
    end
  end
end
