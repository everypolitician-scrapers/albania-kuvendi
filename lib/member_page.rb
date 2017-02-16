# frozen_string_literal: true
require 'scraped'

class MemberPage < Scraped::HTML
  field :birth_date do
    date_from(
      record_for('Datël')
    ).to_s
  end

  field :birth_place do
    record_for('Vendlindja:')
  end

  field :area do
    record_for('Qarku:')
  end

  # TODO: This isn't so easy to extract as the text varies
  # field :commissions do
  #   puts line_for('Komisioni').split(/(Komisioni)/).drop(1).join('').tidy
  # end

  private

  def record_for(str)
    table.xpath(".//span[contains(., '#{str}')]")
         .text
         .split(':', 2)[1]
         .to_s
         .tidy
         .chomp('.')
  end

  def table
    noko.xpath('//div[contains(@class,"post-content")]/table')
  end

  def date_from(text)
    return if text.to_s.tidy.empty?
    Date.parse(text).to_s rescue ''
  end
end
