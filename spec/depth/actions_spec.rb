require 'spec_helper'

module Depth
  RSpec.describe Actions do

    let(:actions_class) do
      Class.new do
        include Actions
        attr_reader :base
        def initialize(base)
          @base = base
        end
      end
    end

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

    subject { actions_class.new(hash) }

    describe '#set' do
      it 'should let me set an existing value' do
        route = [['$and', :array], [0, :hash],
                 ['#weather', :hash], ['something', :array]]
        expect do
          subject.set(route, :test)
        end.to change { hash['$and'][0]['#weather']['something'] }.to(:test)
      end

      it 'should let me set a new value' do
        route = [['$rargh', :array], [0, :hash],
                 ['#weather', :hash], ['something', :array]]
        subject.set(route, :test)
        expect(hash['$rargh'][0]['#weather']['something']).to eq :test
      end
    end

    describe '#delete' do
      context 'when in a hash' do
        let(:route) do
          ['$and', 1, '#weather']
        end

        it 'should let me delete a route endpoint' do
          expect do
            subject.delete(route)
          end.to change { hash['$and'][1].empty? }.to(true)
        end
      end

      context 'when in an array' do
        let(:route) do
          ['$and', 1]
        end

        it 'should let me delete a route endpoint' do
          expect do
            subject.delete(route)
          end.to change { hash['$and'].count }.by(-1)
        end
      end
    end

    describe '#alter' do
      let(:route) do
        [['$and', :array], [0, :hash], ['#weather', :hash], ['something', :array]]
      end

      it 'should let me change a key' do
        expect do
          subject.alter(route, key: 'blah')
        end.to change { hash['$and'][0]['#weather'].keys }.to ['blah']
      end

      it 'should let me change a value' do
        expect do
          subject.alter(route, value: 'rargh')
        end.to change { hash['$and'][0]['#weather']['something'] }.to 'rargh'
      end

      context 'when changing key and value' do
        it 'should set the new value' do
          expect do
            subject.alter(route, key: 'blah', value: 'rargh')
          end.to change { hash['$and'][0]['#weather']['blah'] }.to 'rargh'
        end

        it 'should delete the old key' do
          expect do
            subject.alter(route, key: 'blah', value: 'rargh')
          end.to change { hash['$and'][0]['#weather'].key?('something') }.to false
        end
      end
    end

    describe '#find' do
      it 'should let me find an existing value' do
        route = [['$and', :array], [0, :hash],
                 ['#weather', :hash], ['something', :array]]
        expect(subject.find(route)).to eq []
      end

      it 'should return nil if element does not exist' do
        route = [['$rargh', :array], [0, :hash],
                 ['#weather', :hash], ['something', :array]]
        expect(subject.find(route)).to be_nil
      end
    end
  end
end
