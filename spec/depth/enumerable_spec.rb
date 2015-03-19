
require 'spec_helper'
require 'pry-byebug'

module Depth::Enumeration
  RSpec.describe Enumerable do

    let(:enumerable_class) do
      Class.new do
        include Depth::Enumeration::Enumerable
        attr_reader :base
        def initialize(base)
          @base = base
        end
      end
    end

    let(:hash) do
      { '$and' => [
        { '#weather' => { 'something' => [] } },
        { '$or' => [
          { '#otherfeed' => {'thing' => [] } },
        ]}
      ]}
    end

    subject { enumerable_class.new(hash) }

    describe '#map' do
    end

    describe '#each' do
      it 'should sort through all keys and values' do
        enumerated = []
        subject.each do |key, fragment|
          enumerated << [key, fragment]
        end
        expected = [
          ['something', []],
          ['#weather',  { 'something' => [] }],
          [0,  { '#weather' => {  'something' => []  }}],
          ['thing', []],
          ['#otherfeed', { 'thing' => [] }],
          [0, { '#otherfeed' => { 'thing' => [] } }],
          ['$or', [{ '#otherfeed' => { 'thing' => [] } }]],
          [1, { '$or' => [{ '#otherfeed' => { 'thing' => [] } }] }],
          ['$and', [{ '#weather' => {  'something' => []  }},
                   { '$or' => [{ '#otherfeed' => { 'thing' => [] } }] }]]
        ]
        expect(enumerated).to eq expected
      end
    end

  end
end
