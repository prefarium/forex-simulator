# frozen_string_literal: true

require 'json'
require 'nokogiri'

rate   = {}
dollar = 75.0
euro   = 82.0

# Генерируем историю колебаний курса за 50 минут
# Крупные числа в шапке цикла - это количество секунд
#   с начала отсчёта времени Unix
#   (сами по себе эти числа могут быть любыми))
# 1_589_749_200 => 05/17/2020 @ 9:01pm (UTC)
# 1_589_752_200 => 05/17/2020 @ 9:50pm (UTC)
1_589_749_200.step(1_589_752_200, 60) do |i|
  minute_history = [] # Массив для хранения истории за 1 минуту

  # Генерируем и сохраняем историю за минуту
  60.times do
    dollar = (dollar + rand(-1..1.5)).round(4)
    euro   = (euro   + rand(-0.5..2)).round(4)
    # Для изменения динамики курса отредактируйте разброс значений в rand()
    minute_history << (euro / dollar).round(4)
  end

  # Сохраняем определенные показатели курса для отрисовки свечи в будущем
  rate[i] = { 'start' => minute_history[0],
             'finish' => minute_history[-1],
                'max' => minute_history.max,
                'min' => minute_history.min }
end

# Генерируем стандартные настройки холста и его содержимого
default_settings = Nokogiri::XML::Builder.new do |xml|
  # Параметры холста
  xml.default_settings do
    xml.canvas do
      xml.image_height '720'
      xml.image_width '1280'
      xml.vertical_padding '10'

      xml.grid do
        xml.grid_main_color 'white'
        xml.grid_line_color 'grey95'
        xml.grid_step '10'
      end
    end

    # Внишний вид свечей
    xml.candles do
      xml.density '14'
      xml.thickness '10'
      xml.candle_stroke 'green'
      xml.candle_fill 'green'
      xml.candle_stroke_width '1'
      xml.up_candle_opacity '1'
      xml.down_candle_opacity '0'
      xml.start_date '1589749200'
      xml.finish_date '1589752200'
    end

    # Внешний вид боковой шкалы
    xml.scale do
      xml.scale_margin '10'
      xml.scale_stroke 'black'
      xml.scale_stroke_opacity '0'
      xml.scale_mark_size '10'
    end

    # Шрифт на шкале
    xml.font do
      xml.font_size '14'
      xml.text_left_padding '5'
      xml.text_vert_padding '5'
    end
  end
end.to_xml

current_path = File.dirname(__FILE__)

File.write('data/candles/minute_candles_db.json', rate.to_json)
File.write("#{current_path}/data/default_settings.xml", default_settings)
