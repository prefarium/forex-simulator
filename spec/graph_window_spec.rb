require 'rspec'
require 'rmagick'
require 'json'
require_relative '../classes.rb'


describe 'GraphWindow' do
  before(:all) do
    graph             = GraphWindow.new
    @default_settings = graph.send(:read_settings)
    @settings         = GraphImage.take_and_process(graph.send(:read_settings))
  end


  describe 'read_settings' do
    it 'should return a hash' do
      expect(@default_settings).to be_a Hash
    end


    it 'should return a hash with precisely 22 pairs' do
      expect(@default_settings.size).to eq 22
    end


    it 'sould return a hash with precisely 5 string values' do
      expect(@default_settings[:grid_main_color]).to be_a String
      expect(@default_settings[:grid_line_color]).to be_a String
      expect(@default_settings[:candle_stroke])  .to be_a String
      expect(@default_settings[:candle_fill])    .to be_a String
      expect(@default_settings[:scale_stroke])   .to be_a String
    end


    it 'sould return a hash with precisely 17 integer values' do
      expect(@default_settings.values.count { |v| v.class == Integer }).to eq 17
    end


    it 'should return a hash with only symbols as keys' do
      @default_settings.each_key { |k| expect(k).to be_a Symbol }
    end
  end


  describe 'take and process' do
    it 'should pass to GraphImage class a hash with 32 pairs' do
      expect(GraphImage.settings.size).to eq 32
    end
  end


  describe 'rate_history' do
    before(:all) do
      @history = GraphImage.send(:rate_history)
    end


    it 'should return a hash with only integers as keys' do
      @history.each_key { |k| expect(k).to be_a Integer }
    end


    it 'should return a hash with only hashes as values' do
      @history.each_value { |v| expect(v).to be_a Hash }
    end


    it 'should return a hash with values sizes precisely 4' do
      @history.each_value { |v| expect(v.size).to eq 4 }
    end


    it 'should return a hash with only floats as subhashes values' do
      @history.each_key do |k|
        @history[k].each_value { |v| expect(v).to be_a Float }
      end
    end


    it 'should return a hash with only values greater than 0' +
       'in subhashes values' do

      @history.each_key do |k|
        @history[k].each_value { |v| expect(v).to be > 0 }
      end
    end


    it 'should return a hash with no number bigger than max' +
       'in subhashes values' do

      @history.each_key do |k|
        @history[k].each_value { |v| expect(v).to be <= @history[k]['max'] }
      end
    end


    it 'should return a hash with no number less than min' +
       'in subhashes values' do

      @history.each_key do |k|
        @history[k].each_value { |v| expect(v).to be >= @history[k]['min'] }
      end
    end


    it 'should return a hash with exactly start, finish, min, max strins' +
       'as keys in subhashes values' do

      @history.each_value do |v|
        expect(v.keys.sort).to eq ['finish', 'max', 'min', 'start']
      end
    end
  end


  describe 'amplitude' do
    it 'should always return positive number' do
      expect(GraphImage.send(:amplitude, @settings)).to be > 0
    end
  end


  describe 'scale_ratio' do
    it 'should return a value greater than 0' do
      expect(GraphImage.send(:scale_ratio, @settings)).to be > 0
    end
  end


  describe 'page_bottom' do
    before(:all) do
      rate_value = GraphImage.send(:page_bottom, @settings)
      @y_coord   = GraphImage.new.send(:to_graph, rate_value, @settings)
    end


    it "should never return values that render lower than" +
       "the image's bottom edge" do

      expect(@y_coord).not_to be > @settings[:image_height] - 1
    end


    it "should never return values that render higher than" +
       "the image's bottom edge more than by scale ratio" do

      expect(@y_coord).not_to be <
        @settings[:image_height] - 1 - @settings[:scale_ratio]
    end
  end


  describe 'page_top' do
    before(:all) do
      rate_value = GraphImage.send(:page_top, @settings)
      @y_coord   = GraphImage.new.send(:to_graph, rate_value, @settings)
    end


    it "should never return values that render higher than" +
       "the image's top edge" do

      expect(@y_coord).not_to be < 0
    end


    it "should never return values that render lower than" +
       "the image's top edge more than by scale_ratio" do

      expect(@y_coord).not_to be > @settings[:scale_ratio]
    end
  end


  describe 'find_first_mark' do
    it "should never return values that render lower than" +
       "the image's bottom edge more than by scale_main step" do

      rate_value = GraphImage.send(:find_first_mark, @settings)
      y_coord    = GraphImage.new.send(:to_graph, rate_value, @settings)

      expect(y_coord).not_to be < @settings[:image_height] - 1 -
        @settings[:scale_main_step] * @settings[:scale_ratio]
    end
  end
end