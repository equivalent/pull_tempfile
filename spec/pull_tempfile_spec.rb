require 'spec_helper'

describe PullTempfile do
  it 'has a version number' do
    expect(PullTempfile::VERSION).not_to be nil
  end

  def use_vcr(&block)
    VCR.use_cassette("basic", &block)
  end

  let(:url) { 'http://www.eq8.eu/no-idea.png' }

  it 'should execute block inside' do
    use_vcr do
      called = nil
      described_class.transaction(url: url, original_filename: 'any name you desire.jpg') do |file|
        called = file
      end

      expect(called).to be_kind_of File
    end
  end

  it 'should delete file after transaction finish' do
    use_vcr do
      file_eval = nil

      described_class.transaction(url: url, original_filename: 'any name you desire.jpg') do |file|
        file_eval = file

        expect(File.exist?(file_eval.path)).to be true

        # file name will be like "/tmp/any name you desire20160317-19731-1gjqeq1.jpg"
        regex = /\A\/tmp\/any name you desire\d{8}-.*\.jpg\z/
        expect(file_eval.path.to_s).to match regex
      end

      expect(File.exist?(file_eval.path)).to be false
    end
  end


end
