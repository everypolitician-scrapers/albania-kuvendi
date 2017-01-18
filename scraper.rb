#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def date_from(text)
  return if text.to_s.tidy.empty?
  Date.parse(text).to_s rescue ''
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
    data.merge! scrape_person(data[:source])
    ScraperWiki.save_sqlite(%i(id term), data)
  end

  unless (next_page = noko.css('a.next/@href')).empty?
    scrape_list next_page.text
  end
end

def scrape_person(url)
  noko = noko_for(url)
  box = noko.css('.post-content')
  cells = box.xpath('.//td').map(&:text).map { |t| t.split(Regexp.union("\n",/(Zgjedhur)/)) }.flatten.map(&:tidy).compact.reject(&:empty?)
  unless cells.any?
    warn "No data at #{url}"
    return {}
  end

  member_h = cells.find_index { |t| t.start_with? 'Zgjedhur' } or binding.pry
  groups_h = cells.find_index { |t| t.start_with? 'Grupi' }

  member = cells[member_h + 1..(groups_h ? groups_h - 1 : -1)]
  groups = groups_h ? cells[groups_h + 1..-1] : []

  {
    birth_date:  date_from(cells.find { |t| t.include?('Datëlindja') }),
    birth_place: cells.find(-> { ':' }) { |t| t.include?('Vendlindja') }.split(':', 2).last.tidy.sub(/\.$/, ''),
    area:        member.find(-> { ':' }) { |t| t.include? 'Qarku' }.split(':', 2).last.tidy.sub(/\.$/, ''),
    # faction: groups.find(->{":"}) { |t| t.include? "Grupi parlamentar:" }.split(':', 2).last.tidy.sub(/\.$/,''),
    commissions: groups.find(-> { '' }) { |t| t.include? 'Komisioni' }.tidy,
  } rescue binding.pry
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.parlament.al/atribut/deputet/')
