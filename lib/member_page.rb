# frozen_string_literal: true

require 'scraped'

class MemberPage < Scraped::HTML
  field :birth_date do
    date_from(cells.find { |t| t.include?('Datëlindja') })
  end

  field :birth_place do
    cells.find(-> { ':' }) { |t| t.include?('Vendlindja') }.split(':', 2).last.tidy.sub(/\.$/, '')
  end

  field :area do
    member.find(-> { ':' }) { |t| t.include? 'Qarku' }.split(':', 2).last.tidy.sub(/\.$/, '')
  end

  field :commissions do
    groups.find(-> { '' }) { |t| t.include? 'Komisioni' }.tidy
  end

  private

  def box
    noko.css('.post-content')
  end

  def cells
    box.xpath('.//td').map(&:text).map { |t| t.split("\n") }.flatten.map(&:tidy).compact.reject(&:empty?)
  end

  # TODO: cope with this being missing
  def member_h
    return if cells.empty?
    cells.find_index { |t| t.start_with? 'Zgjedhur' }
  end

  # TODO: ...and this
  def groups_h
    cells.find_index { |t| t.start_with? 'Grupi' }
  end

  def member
    return [] if member_h.nil?
    cells[member_h.to_i + 1..(groups_h ? groups_h - 1 : -1)]
  end

  def groups
    groups_h ? cells[groups_h + 1..-1] : []
  end

  def date_from(text)
    return if text.to_s.tidy.empty?
    Date.parse(text).to_s rescue ''
  end
end
