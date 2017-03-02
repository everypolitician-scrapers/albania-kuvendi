# frozen_string_literal: true
require 'scraped'

class MemberRow < Scraped::HTML
  field :id do
    noko.attr('class')[/post-(\d+)/, 1]
  end

  field :name do
    noko.css('h2').text.tidy
  end

  field :party_id do
    party_id_and_name.first
  end

  field :party do
    party_id_and_name.last
  end

  field :email do
    noko.css('a[href*="@"]/@href').text.sub('mailto:', '')
  end

  field :image do
    noko.css('.fusion-image-wrapper img/@src').text
  end

  field :source do
    noko.css('h2 a/@href').text
  end

  private

  def party_id_and_name
    noko.css('.fusion-portfolio-content h4').text.tidy.split(':', 2)
  end
end
