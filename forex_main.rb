# frozen_string_literal: true

require 'rmagick'
require 'json'
require_relative 'classes.rb'


settings = { 'image_width'          => 1280,
             'image_height'         => 720,
             'vertical_padding'     => 10,
             'left_padding'         => 10,
             'right_padding'        => 10,
             'grid_main_color'      => 'white',
             'grid_line_color'      => 'grey95',
             'grid_step'            => 10,
             'font_size'            => 14,
             'density'              => 14,
             'thickness'            => 10,
             'candle_stroke'        => 'green',
             'candle_fill'          => 'green',
             'candle_stroke_width'  => 1,
             'up_candle_opacity'    => 1,
             'down_candle_opacity'  => 0,
             'start_date'           => 1_589_749_200,
             'finish_date'          => 1_589_752_200,
             'scale_stroke'         => 'black',
             'scale_stroke_opacity' => 0,
             'scale_mark_size'      => 10,
             'text_left_padding'    => 5,
             'text_vert_padding'    => 5 }


graph_window = GraphWindow.new(settings)
graph_window.write('candles_graph.jpg')
