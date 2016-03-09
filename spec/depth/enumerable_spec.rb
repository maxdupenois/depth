
require 'spec_helper'
require 'pry-byebug'

module Depth::Enumeration
  RSpec.describe Enumerable do

    let(:enumerable_class) do
      Class.new do
        include Depth::Actions
        include Depth::Enumeration::Enumerable
        attr_reader :base, :creation_proc, :next_proc,
          :key_transformer
        def initialize(base)
          @base = base
          @creation_proc = proc { |o, k, v| o[k] = v }
          @next_proc = proc { |o, k| o[k] }
          @key_transformer = proc { |_, k| k }
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

    describe '#each_with_object' do
      it "performs as you'd expect reduce to" do
        keys = subject.each_with_object([]) do |key, fragment, obj|
          obj << key if key.is_a?(String)
        end
        expected = ['something', '#weather', 'thing', '#otherfeed', '$or', '$and']
        expect(keys).to eq expected
      end
    end

    describe '#select' do
      let(:hash) do
        { 'x' => 1, '$c' => 2, 'v' => { '$x' => :a }, '$f' => { 'a' => 3, '$l' => 4 }}
      end
      it 'keeps only that which you desire' do
        onlydollars = subject.select do |key, fragment|
          key =~ /^\$/
        end
        expected = {"$c"=>2, "$f"=>{'$l'=>4}}
        expect(onlydollars.base).to eq expected
      end
    end

    describe '#reject' do
      let(:hash) do
        { 'x' => 1, '$c' => 2, 'v' => { '$x' => :a }, '$f' => { 'a' => 3 }}
      end
      it 'reject that which you is not your desire' do
        onlydollars = subject.reject do |key, fragment|
          key =~ /^\$/
        end
        expected = {"x"=>1, "v"=>{}}
        expect(onlydollars.base).to eq expected
      end
    end

    describe '#reduce' do
      it "performs as you'd expect reduce to" do
        keys = subject.reduce(0) do |sum, key, fragment|
          sum += (key.is_a?(String) ? 1 : 0)
        end
        expect(keys).to eq 6
      end
    end

    shared_examples 'it maps changing self' do
      let(:map_block) { proc { |x| x } }
      let(:alter_map_block) { proc { |x| 'rarg' } }

      it 'should return self' do
        result = subject.send(map_message, &map_block)
        expect(result).to be subject
      end

      context 'with alteration' do
        it 'should change base' do
          expect do
            subject.send(map_message, &alter_map_block)
          end.to change { subject.base }
        end
      end

      context 'without alteration' do
        it 'should not change contents' do
          expect do
            subject.send(map_message, &map_block)
          end.to_not change { subject.base }
        end
      end
    end

    describe '#map!' do
      it_behaves_like 'it maps changing self' do
        let(:map_message) { 'map!' }
        let(:map_block) { proc { |x, y| [x, y] } }
        let(:alter_map_block) do
          proc { |k, v| 
            next [k, v] unless k.is_a?(String)
            ["#{k}rargh", v]
          }
        end
      end
    end

    describe '#map_keys!' do
      it_behaves_like 'it maps changing self' do
        let(:map_message) { 'map_keys!' }
        let(:alter_map_block) do
          proc { |k|
            next k unless k.is_a?(String)
            "#{k}Altered"
          }
        end
      end
    end

    describe '#map_values!' do
      it_behaves_like 'it maps changing self' do
        let(:map_message) { 'map_values!' }
      end
    end

    shared_examples 'it maps to a new object' do
      let(:map_block) { proc { |x| x } }
      it 'should return a new object' do
        result = subject.send(map_message, &map_block)
        expect(result).to_not be subject
      end

      it 'should return an object of the same class' do
        result = subject.send(map_message, &map_block)
        expect(result.class).to be subject.class
      end

      context 'without alteration' do
        it 'should return an object with the same contents' do
          result = subject.send(map_message, &map_block)
          expect(result.base).to eq subject.base
        end
      end
    end

    describe '#map' do
      it_behaves_like 'it maps to a new object' do
        let(:map_message) { :map }
        let(:map_block) { proc { |x, y| [x, y] } }
      end

      context 'with alteration' do
        let(:result) do
          subject.map do |k, v, r|
            next [k, v] unless k.is_a?(String)
            ["#{k}Altered", 'redacted']
          end
        end

        it 'should differ in the expected fashion' do
          expected =  { "$andAltered" => 'redacted' }
          expect(result.base).to eq expected
        end
      end
    end

    describe '#map_keys' do
      it_behaves_like 'it maps to a new object' do
        let(:map_message) { :map_keys }
      end

      context 'with alteration' do
        let(:result) do
          subject.map_keys do |k|
            next k unless k.is_a?(String)
            "#{k}Altered"
          end
        end

        it 'should differ in the expected fashion' do
          expected =  { "$andAltered" => [
            { "#weatherAltered" => { "somethingAltered" => [] } },
            { "$orAltered" => [ { "#otherfeedAltered" => { "thingAltered" => [] } } ] } ]
          }
          expect(result.base).to eq expected
        end
      end
    end

    describe '#map_values' do
      it_behaves_like 'it maps to a new object' do
        let(:map_message) { :map_values }
      end

      context 'with alteration' do
        let(:result) do
          subject.map_values do |f|
            'altered' if f.is_a?(Hash)
          end
        end

        it 'should differ in the expected fashion' do
          expected = { "$and" => [ 'altered', 'altered' ] }
          expect(result.base).to eq expected
        end

        it 'should return an object with the different contents' do
          expect(result.base).to_not eq subject.base
        end
      end

    end

    describe '#each' do
      it 'should keep track of where we are' do
        routes = []
        subject.each do |_, _, route|
          routes << route
        end

        expected = [
          ["$and", 0, "#weather", "something"], ["$and", 0, "#weather"],
          ["$and", 0], ["$and", 1, "$or", 0, "#otherfeed", "thing"],
          ["$and", 1, "$or", 0, "#otherfeed"], ["$and", 1, "$or", 0],
          ["$and", 1, "$or"], ["$and", 1], ["$and"]
        ]

        expect(routes).to eq(expected)
      end

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
