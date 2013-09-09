require 'spec_helper'
require 'pact/provider/dsl'

module Pact::Provider
  describe DSL do

    class MockConfig
      include Pact::Provider::DSL
    end

    describe "service_provider" do

      before do
        Pact.clear_configuration
      end

      let(:mock_config) { MockConfig.new }
      context "when a provider is configured" do
        before do
          mock_config.service_provider "Fred" do
            app { "An app" }
          end
        end
        it "should allow configuration of the name" do
          expect(Pact.configuration.provider.name).to eql "Fred"
        end
        it "should allow configuration of the test app" do
          expect(Pact.configuration.provider.app).to eql "An app"
        end
      end
      #Move this test to configuration
      context "when a provider is not configured" do
        it "raises an error" do
          expect{ Pact.configuration.provider }.to raise_error(/Please configure your provider/)
        end
      end
    end


    module DSL

      describe VerificationDSL do


        describe 'create_verification' do
          let(:url) {'http://some/uri'}
          let(:consumer_name) {'some consumer'}
          let(:ref) {:prod}
          let(:options) { {:ref => :prod} }
          context "with valid values" do
            subject do
              uri = url
              VerificationDSL.new(consumer_name, options) do
                uri uri
              end
            end

            it "creates a Verification" do
              Pact::Provider::PactVerification.should_receive(:new).with(consumer_name, url, ref)
              subject.create_verification
            end

            it "returns a Verification" do
              Pact::Provider::PactVerification.should_receive(:new).and_return('a verification')
              expect(subject.create_verification).to eq('a verification')
            end
          end

          context "with a nil uri" do
            subject do
              VerificationDSL.new(consumer_name, options) do
                uri nil
              end
            end

            it "raises a validation error" do
              expect{ subject.create_verification}.to raise_error /Please provide a uri/
            end
          end
        end
      end

      describe ServiceProviderDSL do

        describe "initialize" do

          context "with an object instead of a block" do
            subject do
              ServiceProviderDSL.new 'name' do
                app 'blah'
              end
            end
            it "raises an error" do
              expect{ subject }.to raise_error /wrong number of arguments/
            end
          end

        end
        describe "validate" do
          context "when no name is provided" do
            subject do
              ServiceProviderDSL.new ' ' do
                app { Object.new }
              end
            end
            it "raises an error" do
              expect{ subject.validate}.to raise_error("Please provide a name for the Provider")
            end
          end
          context "when nil name is provided" do
            subject do
              ServiceProviderDSL.new nil do
                app { Object.new }
              end
            end
            it "raises an error" do
              expect{ subject.validate}.to raise_error("Please provide a name for the Provider")
            end
          end
          context "when no app is provided" do
            subject do
              ServiceProviderDSL.new 'Blah' do
              end
            end
            it "raises an error" do
              expect{ subject.validate }.to raise_error("Please configure an app for the Provider")
            end
          end
        end

        describe 'honours_pact_with' do
          before do
            Pact.clear_configuration
          end

          context "with no optional params" do
            subject do
              ServiceProviderDSL.new '' do
                honours_pact_with 'some-consumer' do
                  uri 'blah'
                end
              end
            end
            it 'adds a verification to the Pact.configuration' do
              subject
              expect(Pact.configuration.pact_verifications.first).to eq(Pact::Provider::PactVerification.new('some-consumer', 'blah', :head))
            end
          end

          context "with all params specified" do
            subject do
              ServiceProviderDSL.new '' do
                honours_pact_with 'some-consumer', :ref => :prod do
                  uri 'blah'
                end
              end
            end
            it 'adds a verification to the Pact.configuration' do
              subject
              expect(Pact.configuration.pact_verifications.first).to eq(Pact::Provider::PactVerification.new('some-consumer', 'blah', :prod))
            end

          end

        end
      end

      describe ServiceProviderConfig do
        describe "app" do
          subject { ServiceProviderConfig.new("blah") { Object.new } }
          it "should execute the app_block each time" do
            expect(subject.app.object_id).to_not equal(subject.app.object_id)
          end
        end
      end

    end
  end
end