require 'rails_helper'

RSpec.describe LalenApi::AssignKitTestsJob, type: :job do
  include ActiveJob::TestHelper

  let(:barcode) { "AU1234567" }
  let(:api_keys) { ["vitamin-d", "hba1c"] }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:response_201) { instance_double(Faraday::Response, status: 201) }
  let(:response_404) { instance_double(Faraday::Response, status: 404) }
  let(:response_422) { instance_double(Faraday::Response, status: 422) }

  before do
    allow(LalenApi::Client.instance).to receive(:connection).and_return(connection)
  end

  describe '#perform' do
    subject(:job) { described_class.new }

    it 'is in the background queue' do
      expect(job.queue_name).to eq('background')
    end

    context 'when external API returns 201' do
      it 'posts to kit_tests and completes without error' do
        expect(connection).to receive(:post).with(
          'kit_tests',
          { "barcode" => barcode, "tests" => api_keys },
          "Content-Type" => "application/json"
        ).and_return(response_201)

        expect { job.perform(barcode, api_keys) }.not_to raise_error
      end
    end

    context 'when external API returns 404' do
      it 'returns silently without raising' do
        allow(connection).to receive(:post).and_return(response_404)
        expect { job.perform(barcode, api_keys) }.not_to raise_error
      end
    end

    context 'when external API returns non-201/non-404' do
      it 'raises LalenApi::Error' do
        allow(connection).to receive(:post).and_return(response_422)
        expect { job.perform(barcode, api_keys) }.to raise_error(LalenApi::Error)
      end
    end

    context 'when barcode is blank' do
      it 'raises LalenApi::Error before making HTTP call' do
        expect(connection).not_to receive(:post)
        expect { job.perform("", api_keys) }.to raise_error(LalenApi::Error)
      end
    end

    context 'when tests array is empty' do
      it 'raises LalenApi::Error before making HTTP call' do
        expect(connection).not_to receive(:post)
        expect { job.perform(barcode, []) }.to raise_error(LalenApi::Error)
      end
    end
  end
end
