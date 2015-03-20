require 'spec_helper'

module Depth
  RSpec.describe ComplexHash do
    let(:hash) do
      { '$and' => [
        { '#weather' => { 'something' => [] } },
        { '#weather' => { 'something' => [] } },
        { '#weather' => { 'something' => [] } },
        { '$or' => [
          { '#otherfeed' => {'thing' => [] } },
        ]}
      ]}
    end

    subject { described_class.new(hash) }

    describe '#base' do
      it 'should return the underlying hash' do
        expect(subject.base).to eq hash
      end
    end

    describe '#to_h' do
      it 'should be aliased to base' do
        expect(subject.to_h).to be subject.base
      end
    end
  end
end
