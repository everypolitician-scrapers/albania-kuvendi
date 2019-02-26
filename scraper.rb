#!/bin/env ruby
# frozen_string_literal: true

require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    data = member_urls.map { |url| Scraped::Scraper.new(url => MemberPage).scraper.to_h }
    return [] if data.empty?
    return data unless next_page

    data + Scraped::Scraper.new(next_page => MembersPage).scraper.members
  end

  private

  def member_cells
    noko.css('.col-md-3')
  end

  def member_urls
    member_cells.map { |mp| fragment(mp => MemberCell).url }
  end

  def next_link
    noko.xpath('//ul[@class="pagination"]//a[.="Pas"]')
  end

  def next_page
    return if next_link.attr('onclick').to_s.include?('return false')

    next_link.attr('href')
  end
end

class MemberCell < Scraped::HTML
  field :url do
    noko.css('a/@href').text
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.split('/').last
  end

  field :name do
    [given_name, family_name].join(' ')
  end

  field :sort_name do
    [family_name, given_name].join(' ')
  end

  field :family_name do
    box.xpath('.//td[contains(.,"Mbiemër:")]//following-sibling::td').text.tidy
  end

  field :given_name do
    box.xpath('.//td[contains(.,"Emër:")]//following-sibling::td').text.tidy
  end

  field :birth_date do
    return if dob == '-'

    dob.split('.').reverse.join('-')
  end

  field :email do
    box.xpath('.//td[contains(.,"Email:")]//following-sibling::td').text.tidy
  end

  field :image do
    box.css('img/@src').text
  end

  private

  def box
    noko.css('.panel-body')
  end

  def dob
    box.xpath('.//td[contains(.,"Datëlindje:")]//following-sibling::td').text.tidy
  end
end

url = 'http://www.parlament.al/Anetar/AllAnetar'
Scraped::Scraper.new(url => MembersPage).store(:members)
