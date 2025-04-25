# frozen_string_literal: true

require_relative '../lib/extract_agi'
require 'json'

RSpec.describe ExtractAgi::WordParser do
  let(:file_path) { File.expand_path('../kq1/WORDS.TOK', __dir__) }
  let(:parsed_words_path) { File.expand_path('../kq1/parsed_words.json', __dir__) }
  let(:parsed_index_path) { File.expand_path('../kq1/parsed_index.json', __dir__) }
  let(:parser) { described_class.new(file_path: file_path) }

  it 'parses kq1 words correctly' do
    expect(parser.parse_words).to eq(JSON.parse(File.read(parsed_words_path)).transform_keys(&:to_i))
  end

  it 'parses kq1 index correctly' do
    expect(parser.parse_index).to eq(JSON.parse(File.read(parsed_index_path)))
  end
end
