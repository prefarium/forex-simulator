# frozen_string_literal: true

require 'rmagick'
require 'json'
require_relative 'classes.rb'


graph_window = GraphWindow.new
graph_window.write('candles_graph.jpg')
