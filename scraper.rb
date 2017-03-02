#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
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

def member_rows(url, rows = nil)
  members_page = (scrape url => MembersPage)
  rows = rows.to_a + members_page.member_rows
  return rows if members_page.next_page.empty?
  member_rows(members_page.next_page.text, rows)
end

def urls_to_skip
  [
    'https://www.parlament.al/deputet/genc-ruli/',
    'https://www.parlament.al/deputet/gramoz-ruci/',
    'https://www.parlament.al/deputet/myqerem-tafaj/',
  ]
end

data = member_rows('http://www.parlament.al/atribut/deputet/').map(&:to_h)
                                                              .map do |row|
  row.merge!((scrape row[:source] => MemberPage).to_h) unless urls_to_skip.include? row[:source]
  row.merge(term: 8)
end

# data.each { |d| puts d.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h }
ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i(id term), data)
