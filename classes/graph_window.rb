# frozen_string_literal: true

# Данный класс отвечает за создание холста и отрисовку графика
class GraphWindow < Magick::ImageList
  def initialize
    super

    # Загружаем стандартные настройки
    settings = read_settings

    # Генерируем холст
    new_image(settings[:image_width],
              settings[:image_height],
              Magick::HatchFill.new(settings[:grid_main_color],
                                    settings[:grid_line_color],
                                    settings[:grid_step]))

    # Рассчитывамем параметры, необходимые для отрисовки,
    #   используя имеющиеся настройки
    GraphImage.take_and_process(settings)

    # Рисуем на холсте
    Candles.new.draw(self)
    LeftScale.new.draw(self)
  end

  private

  def read_settings
    current_path = File.dirname(__FILE__)
    # Парсим файл настроек с помощью регулярного выражения,
    #   чтобы получить настройки в виде пар ключ-значение
    doc = File.read("#{current_path}/../data/default_settings.xml")
              .scan(%r{
                       <(\w+)> # Открывающий тег - ключ
                        (\w+)  # Содержание тега - значение
                       </\1>   # Закрывающий тег
                      }x)

    settings = {}

    # Полученный массив с настроек трансформируем в хэш
    # (Регулярка проверяет, является ли строка числом - содержит только цифры)
    doc.each do |i|
      settings[i[0].to_sym] = i[1].match(/\A\d+\z/) ? i[1].to_i : i[1]
    end

    settings
  end
end
