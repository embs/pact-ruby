require 'net/http'
require 'pact/consumer'
require 'pact/consumer/rspec'

describe "A service consumer side of a pact", :pact => true  do

  it "goes a little something like this" do
    alice_service = consumer('consumer').assuming_a_service('Alice').
    on_port(1234).
      upon_receiving("a retrieve Mallory request").with({
      method: :get,
      path: '/mallory'
    }).
      will_respond_with({
      status: 200,
      headers: { 'Content-Type' => 'text/html' },
      body: Pact::Term.new(matcher: /Mallory/, generate: 'That is some good Mallory.')
    })

    bob_service = consumer('consumer').assuming_a_service('Bob').
    on_port(4321).
      upon_receiving('a create donut request').with({
      method: :post,
      path: '/donuts',
      body: {
        "name" => Pact::Term.new(matcher: /Bob/)
      }
    }).
      will_respond_with({
      status: 201,
      body: 'Donut created.'
    }).
      upon_receiving('a delete charlie request').with({
      method: :delete,
      path: '/charlie'
    }).
      will_respond_with({
      status: 200,
      body: /deleted/
    }).
      upon_receiving('an update alligators request').with({
        method: :put,
        path: '/alligators',
        body: [{"name" => 'Roger' }]
    }).
      will_respond_with({
        status: 200,
        body: [{"name" => "Roger", "age" => 20}]
    })


    alice_response = Net::HTTP.get_response(URI('http://localhost:1234/mallory'))

    expect(alice_response.code).to eql '200'
    expect(alice_response['Content-Type']).to eql 'text/html'
    expect(alice_response.body).to eql 'That is some good Mallory.'

    uri = URI('http://localhost:4321/donuts')
    post_req = Net::HTTP::Post.new(uri.path)
    post_req.body = {"name" => "Bobby"}.to_json
    bob_post_response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request post_req
    end

    expect(bob_post_response.code).to eql '201'
    expect(bob_post_response.body).to eql 'Donut created.'

    uri = URI('http://localhost:4321/alligators')
    post_req = Net::HTTP::Put.new(uri.path)
    post_req.body = [{"name" => "Roger"}].to_json
    bob_post_response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request post_req
    end

    expect(bob_post_response.code).to eql '200'
    expect(bob_post_response.body).to eql([{"name" => "Roger", "age" => 20}].to_json)
  end

  context "with a producer state" do
    it "goes like this" do
      alice_service = consumer('consumer').assuming_a_service('Alice').
        on_port(1235).
        given(:the_zebras_are_here).
        upon_receiving("a retrieve Mallory request").with({
          method: :get,
          path: '/mallory'
        }).
        will_respond_with({
          status: 200,
          headers: { 'Content-Type' => 'text/html' },
          body: Pact::Term.new(matcher: /Mallory/, generate: 'That is some good Mallory.')
        })

        interactions = Pact::ConsumerContract.from_json(File.read(alice_service.pactfile_path)).interactions
        interactions.first['producer_state'].should eq("the_zebras_are_here")
    end
  end

end

