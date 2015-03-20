require 'spec_helper'

module Depth
  RSpec.describe RouteElement do
    describe '::convert' do
      let(:el) { nil }
      let(:result) { described_class.convert(el) }

      context 'with a hash' do
        let(:el) { { key: 'x', type: :array } }

        it 'should set the type as the passed type' do
          expect(result.type).to eq el.fetch(:type)
        end

        it 'should set the key as the passed key' do
          expect(result.key).to eq el.fetch(:key)
        end

        context 'with no type' do
          let(:el) { { key: 'x' } }

          it 'should set the type hash' do
            expect(result.type).to eq :hash
          end
        end

        context 'with index instead of key' do
          let(:el) { { index: 'x', type: :array } }

          it 'should set the key as the passed index' do
            expect(result.key).to eq el.fetch(:index)
          end
        end
      end

      context 'with an array with' do
        context 'with two elements' do
          let(:el) { ['x', :array] }

          it 'should set the type as the second element' do
            expect(result.type).to eq el[1]
          end

          it 'should set the key as the first element' do
            expect(result.key).to eq el[0]
          end
        end

        context 'with one element' do
          let(:el) { ['x'] }

          it 'should set the type hash' do
            expect(result.type).to eq :hash
          end

          it 'should set the key as the element' do
            expect(result.key).to eq el[0]
          end
        end
      end

      context 'with a route element' do
        let(:el) { RouteElement.new('x') }

        it 'should return the element' do
          expect(result).to be el
        end
      end
    end
  end
end
