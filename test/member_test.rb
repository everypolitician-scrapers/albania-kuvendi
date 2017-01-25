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

describe 'Member page with complete data' do
  around { |test| VCR.use_cassette('RuliGenc', &test) }

  subject do
    url = 'https://www.parlament.al/deputet/genc-ruli/'
    MemberPage.new(response: Scraped::Request.new(url: url).response)
  end

  it 'should have the expected data' do
    subject.to_h.must_equal(area:        'Gjirokastër',
                            birth_date:  '1958-04-11',
                            birth_place: 'Tiranë')
  end
end

describe 'Member page without area data' do
  around { |test| VCR.use_cassette('DukaAgron', &test) }

  subject do
    url = 'https://www.parlament.al/deputet/agron-duka-2/'
    MemberPage.new(response: Scraped::Request.new(url: url).response)
  end

  it 'should have the expected data' do
    subject.to_h.must_equal(area:        '',
                            birth_date:  '1958-01-22',
                            birth_place: 'Shijak')
  end
end
