# frozen_string_literal: true
require_relative './test_helper'
require_relative '../lib/member_page.rb'

describe MemberPage do
  around { |test| VCR.use_cassette(File.basename(url), &test) }

  let(:yaml_data) { YAML.load_file(subject) }
  let(:url)       { yaml_data[:url] }
  let(:response)  { MemberPage.new(response: Scraped::Request.new(url: url).response) }

  describe 'member with no data' do
    subject { 'test/data/BlendiKlosi.yml' }
    it 'should contain empty values' do
      yaml_data[:to_h].must_equal response.to_h
    end
  end

  describe 'member with data' do
    subject { 'test/data/ArbenImami.yml' }
    it 'should contain the expected data' do
      yaml_data[:to_h].must_equal response.to_h
    end
  end
end
