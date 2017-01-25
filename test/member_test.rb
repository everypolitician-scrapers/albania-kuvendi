# frozen_string_literal: true
require_relative './test_helper'
require_relative '../lib/member_page.rb'

describe 'Member page without any data' do
  around { |test| VCR.use_cassette('AlfredPeza', &test) }

  subject do
    url = 'https://www.parlament.al/deputet/alfred-peza/'
    MemberPage.new(response: Scraped::Request.new(url: url).response)
  end

  it 'should have the expected data' do
    subject.to_h.must_equal(birth_date:  '',
                            birth_place: '',
                            area:        '')
  end
end
