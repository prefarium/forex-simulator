require 'rspec'
require 'rmagick'
require 'json'
require_relative '../classes.rb'


describe 'read_settings' do

  before(:each) do
    graph = GraphWindow.new
    @x = graph.send(:read_settings)
  end

  it 'should return a hash' do
    expect(@x).to be_a Hash
  end

  it 'should contain 22 pairs' do
    expect(@x.size).to eq 22
  end

  it 'should not contain nil values' do
    @x.each_value { |v| expect(v).not_to be_nil }
  end
end
