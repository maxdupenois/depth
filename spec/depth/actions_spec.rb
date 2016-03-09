require 'spec_helper'

module Depth
  RSpec.describe Actions do

    let(:actions_class) do
      Class.new do
        include Actions
        attr_reader :base, :next_proc, :creation_proc,
          :key_transformer
        def initialize(base, next_proc:, key_transformer:, creation_proc:)
          @base = base
          @next_proc = next_proc
          @creation_proc = creation_proc
          @key_transformer = key_transformer
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

    let(:next_proc) { proc { |o, k| o[k] } }
    let(:creation_proc) { proc { |o, k, v| o[k] = v } }
    let(:key_transformer) { proc { |_, k| k } }

    subject do
      actions_class.new(
        hash, next_proc: next_proc,
        creation_proc: creation_proc,
        key_transformer: key_transformer
      )
    end

    describe '#set' do
      context 'with a key transformer' do
        let(:key_transformer) do
          proc { |_, k|
            next(k) if k.to_s !~ /index_/
            k.gsub(/index_/, '').to_i
          }
        end

        it 'should still work' do
          route = [['$and', :array], ['index_0', :hash],
                   ['#weather', :hash], ['something', :array]]
          expect do
            subject.set(route, :test)
          end.to change { hash['$and'][0]['#weather']['something'] }.to(:test)
        end
      end

      context 'with a custom creation proc' do
        let(:creation_proc) do
          proc { |o, k, v| o[k] = '2' }
        end

        it 'should let me change the creation proc' do
          route = [['$and', :array], [0, :hash],
                   ['#weather', :hash], ['something', :array]]
          expect do
            subject.set(route, :test)
          end.to change { hash['$and'][0]['#weather']['something'] }.to('2')

        end
      end

      context 'with a custom next proc' do
        let(:next_proc) do
          proc { |obj, key|
            if(obj.is_a?(Array))
              obj.at(key)
            else
              obj.fetch(key)
            end
          }
        end

        it 'should allow me to change how I traverse the route' do
          route = [['$and', :array], [0, :hash],
                   ['#weather', :hash], ['something', :array]]
          expect do
            subject.set(route, :test)
          end.to change { hash['$and'][0]['#weather']['something'] }.to(:test)
        end
      end

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
      context 'with create true' do
        it 'should create the route if it needs to' do
          route = [['$yo', :array], 0, '$thing']
          expect {
            subject.find(route, create: true)
          }.to change { subject.base['$yo'] }.to( [{}] )
        end

        context 'with a default value' do
          it 'should create the route and value it needs to' do
            route = [['$yo', :array], 0, '$thing']
            expect {
              subject.find(route, create: true, default: 4)
            }.to change { subject.base['$yo'] }.to( [{'$thing' => 4}] )
          end
        end
      end

      context 'with a default value and a missing route' do
        it 'should return the default' do
          route = ['$yo', 0, '$thing']
          expect(subject.find(route, default: 'blah')).to eq 'blah'
        end
      end

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
