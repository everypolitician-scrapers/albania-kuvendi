#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'fuzzy_match'
require 'pry'
require 'rest-client'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def _prior_names
  morph_api_key = ENV["MORPH_API_KEY"]
  api_url = 'https://api.morph.io/tmtmtmtm/albania-assembly-wp/data.json'

  return JSON.parse(RestClient.get(api_url, params: {
    key: morph_api_key,
    query: "SELECT name FROM data"
  }), symbolize_names: true).map { |n| n[:name] }
end

def fuzzer
  @fuzzer ||= FuzzyMatch.new(_prior_names)
end

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

# Members
  sort_name = box.at_css('h1').text.tidy

  data = { 
    id: File.basename(url, '.*')[/(\d+)/, 1],
    name: sort_name.split(/,\s*/, 2).reverse.join(" "),
    sort_name: sort_name,
    image: box.css('.dl_image_comment_text img/@src').text,
    birth_date: date_from(box.xpath('//text()[contains(.,"Datëlindja")]').text),
    faction: box.xpath('.//h1[contains(.,"Grupi")]/following::text()[contains(translate(.,"GP","gp"),"grupi parlamentar")]').text.tidy.sub(/Grupi Parlamentar[ :i]* /i,'').sub('-së','').sub(/\.$/,''),
    area: box.xpath('.//h1[contains(.,"Zgjedhur")]/following::text()[contains(.,"Qarku")]').text.sub(/.*Qarku:?/,'').tidy,
    term: '8',
    source: url.to_s,
  }

  # Consolidate the name with the previous scraper
  match = fuzzer.find_with_score(data[:name])
  confidence = match[1].to_f * 100
  if confidence > 70
    # warn "Renaming #{data[:name]} to #{match[0]} (%.1f%%)".green % confidence if confidence < 90
    data[:name] = match[0]
  else
    # warn "No good match for #{data[:name]} (#{match})".yellow if confidence > 50
  end

  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.parlament.al/web/Jeteshkrime_7033_1.php')
