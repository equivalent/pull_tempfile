require 'spec_helper'

describe PullTempfile do
  it 'has a version number' do
    expect(PullTempfile::VERSION).not_to be nil
  end

  def use_vcr(&block)
    VCR.use_cassette("basic", &block)
  end

  let(:url) { 'http://www.eq8.eu/no-idea.png' }

  describe '.pull_tempfile' do
    it 'should create tmp file' do
      use_vcr do
        begin
          file = described_class.pull_tempfile(original_filename: 'whatever.jpg', url: url)

          expect(file.path.to_s).to match(/\A\/tmp\/whatever\d{8}-.*\.jpg\z/)
          expect(File.size(file.path.to_s)).to be 232_921

        ensure
          file.unlink
        end
      end
    end
  end

  describe '.transaction' do
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
end
