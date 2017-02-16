# frozen_string_literal: true
require_relative './test_helper'
require_relative '../lib/member_page.rb'

describe 'member data' do
  around { |test| VCR.use_cassette(url.split('/').last, &test) }
  subject { MemberPage.new(response: Scraped::Request.new(url: url).response) }

  describe 'Member page without any data' do
    let(:url) { 'https://www.parlament.al/deputet/alfred-peza/' }

    it 'should have the expected data' do
      subject.to_h.must_equal(birth_date:  '',
                              birth_place: '',
                              area:        '')
    end
  end

  describe 'Member page with complete data' do
    let(:url) { 'https://www.parlament.al/deputet/genc-ruli/' }

    it 'should have the expected data' do
      subject.to_h.must_equal(area:        'Gjirokastër',
                              birth_date:  '1958-04-11',
                              birth_place: 'Tiranë')
    end
  end

  describe 'Member page without area data' do
    let(:url) { 'https://www.parlament.al/deputet/agron-duka-2/' }

    it 'should have the expected data' do
      subject.to_h.must_equal(area:        '',
                              birth_date:  '1958-01-22',
                              birth_place: 'Shijak')
    end
  end

  # There is a case where the text "Vendlindja" (birth place) is displayed
  # but no birth date is given
  describe 'Member without birth place data but with "Vendlindja:" on page' do
    let(:url) { 'https://www.parlament.al/deputet/andrea-marto/' }

    it 'should have the expected data' do
      subject.to_h.must_equal(area:        '',
                              birth_place: '',
                              birth_date:  '1957-09-05')
    end
  end
end
