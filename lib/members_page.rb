# frozen_string_literal: true
require 'scraped'
require_relative './member_row'

class MembersPage < Scraped::HTML
  field :member_rows do
    noko.css('.fusion-portfolio-post').map do |row|
      fragment row => MemberRow
    end
  end

  field :next_page do
    noko.css('a.next/@href')
  end
end
