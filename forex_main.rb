# frozen_string_literal: true

require 'rmagick'
require 'json'
require_relative 'methods.rb'


rate = JSON.parse(File.read('candles_db.json'))

density          = 16 # плотность отображения японских свеч
thickness        = 10 # толщина одной свечи
vertical_padding = 10 # отступ оn верха и низа

top_extremum = to_points(rate.map { |x| x[1]['max'] }.max)
low_extremum = to_points(rate.map { |x| x[1]['min'] }.min)
scale_ratio  = (720.0 - vertical_padding * 2) / (top_extremum - low_extremum)


canvas = Magick::ImageList.new
canvas.new_image(1280, 720, Magick::HatchFill.new('white', 'gray93'))


candle = Magick::Draw.new
candle.stroke('green')
candle.fill('green')
candle.stroke_width(1)


50.times do |i|
  if rate[i.to_s]['start'] < rate[i.to_s]['finish']
    candle.fill_opacity(1)
  else
    candle.fill_opacity(0)
  end


  candle.rectangle(
    i * density,
    (top_extremum - to_points(rate[i.to_s]['start'])) * scale_ratio + 10,

    i * density + thickness,
    (top_extremum - to_points(rate[i.to_s]['finish'])) * scale_ratio + 10 + 1
  )


  high_end = [rate[i.to_s]['start'], rate[i.to_s]['finish']].max
  low_end  = [rate[i.to_s]['start'], rate[i.to_s]['finish']].min
  middle   = i * density + thickness / 2


  if rate[i.to_s]['max'] != high_end
    candle.line(
      middle,
      (top_extremum - to_points(high_end)) * scale_ratio + 10,

      middle,
      (top_extremum - to_points(rate[i.to_s]['max'])) * scale_ratio + 10
    )
  end

  if rate[i.to_s]['min'] != low_end
    candle.line(
      middle,
      (top_extremum - to_points(low_end)) * scale_ratio + 10 + 1,

      middle,
      (top_extremum - to_points(rate[i.to_s]['min'])) * scale_ratio + 10
    )
  end
end


candle.draw(canvas)
canvas.write('candles_graph.jpg')
