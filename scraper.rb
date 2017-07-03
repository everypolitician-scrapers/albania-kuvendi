#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.fusion-portfolio-post').each do |p|
    party_id, party = p.css('.fusion-portfolio-content h4').text.tidy.split(':', 2)
    data = {
      id:       p.attr('class')[/post-(\d+)/, 1],
      name:     p.css('h2').text.tidy,
      party_id: party_id,
      party:    party,
      email:    p.css('a[href*="@"]/@href').text.sub('mailto:', ''),
      term:     8,
      image:    p.css('.fusion-image-wrapper img/@src').text,
      source:   p.css('h2 a/@href').text,
    }
    data.merge!((scrape data[:source] => MemberPage).to_h)
    # puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
    ScraperWiki.save_sqlite(%i[id term], data)
  end

  unless (next_page = noko.css('a.next/@href')).empty?
    scrape_list next_page.text
  end
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.parlament.al/atribut/deputet/')
