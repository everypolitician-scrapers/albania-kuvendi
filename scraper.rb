#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def scrape_list(url)
  members_page = scrape url => MembersPage
  members_page.member_rows.each do |member|
    data = member.to_h
                 .merge(term: 8)
                 .merge((scrape member.source => MemberPage).to_h)
    # puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
    ScraperWiki.save_sqlite(%i(id term), data)
  end

  unless (next_page = members_page.next_page).empty?
    scrape_list next_page.text
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.parlament.al/atribut/deputet/')
