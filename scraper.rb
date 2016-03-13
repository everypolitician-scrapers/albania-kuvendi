#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def date_from(text)
  return if text.to_s.tidy.empty?
  Date.parse(text).to_s  rescue ''
end
  

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.li_standart_list .item_title a/@href').each do |href|
    scrape_person(href.text)
  end

  unless (next_page = noko.css('span.next_page a/@href')).empty?
    scrape_list next_page.text
  end
end

def scrape_person(url)
  noko = noko_for(url)
  box = noko.css('.list-center-component')

  sort_name = box.at_css('h1').text.tidy
  name = sort_name.split(/,\s*/, 2).reverse.join(" ")

  data = { 
    id: File.basename(url, '.*')[/(\d+)/, 1],
    name: name,
    sort_name: sort_name,
    image: box.css('.dl_image_comment_text img/@src').text,
    birth_date: date_from(box.xpath('//text()[contains(.,"Datëlindja")]').text),
    faction: box.xpath('.//h1[contains(.,"Grupi")]/following::text()[contains(translate(.,"GP","gp"),"grupi parlamentar")]').text.tidy.sub(/Grupi Parlamentar[ :i]* /i,'').sub('-së','').sub(/\.$/,''),
    area: box.xpath('.//h1[contains(.,"Zgjedhur")]/following::text()[contains(.,"Qarku")]').text.sub(/.*Qarku:?/,'').tidy,
    term: '8',
    source: url.to_s,
  }

  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.parlament.al/web/Jeteshkrime_7033_1.php')
