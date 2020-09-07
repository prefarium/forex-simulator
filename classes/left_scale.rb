# frozen_string_literal: true

# Класс, представляюший левую шкалу
class LeftScale < GraphImage
  def initialize
    super

    settings = GraphImage.settings

    # Устанавливаем внешний вид шкалы
    stroke(settings[:scale_stroke])
    stroke_opacity(settings[:scale_stroke_opacity])
    pointsize(settings[:font_size])
    text_undercolor('#FFFFFFA5')

    line(settings[:scale_margin],
         0,
         settings[:scale_margin],
         settings[:image_height])

    draw_main_marks(settings)
    draw_small_marks(settings)
  end

  private

  def draw_main_marks(settings)
    settings[:first_mark].step(settings[:page_top],
                               settings[:scale_main_step]) do |mark|
      y_coord_cashe = to_graph(mark, settings)

      line(settings[:scale_margin],
           y_coord_cashe,
           settings[:scale_margin] + settings[:scale_mark_size],
           y_coord_cashe)

      text(settings[:scale_margin] + settings[:text_left_padding],
           y_coord_cashe - settings[:text_vert_padding],
           mark_value(mark))
    end
  end

  # Приводит все марки к виду 2.1000, 0.0500, 3.0090
  def mark_value(mark)
    mark = mark.to_s
    (5 - mark.size).times { mark.prepend('0') } if mark.size < 5
    mark.insert(-5, '.')
  end

  def draw_small_marks(settings)
    # Уменьшаем размер шапок циклов, назначая значения настроек переменным
    first_mark = settings[:first_mark]
    top        = settings[:page_top]
    bottom     = settings[:page_bottom]
    step       = settings[:scale_small_step]

    # Отрисовываем засечки вверх от первой
    first_mark.step(top, step) do |mark|
      # Если малая засечка попадает на основную, то её не рисуем
      if mark % settings[:scale_main_step]
        y_coord_cashe = to_graph(mark, settings)

        line(settings[:scale_margin],
             y_coord_cashe,
             settings[:scale_margin] + settings[:scale_mark_size] / 2,
             y_coord_cashe)
      end
    end

    # Отрисовываем засечки вниз от первой
    (first_mark - step).step(bottom, - step) do |mark|
      y_coord_cashe = to_graph(mark, settings)

      line(settings[:scale_margin],
           y_coord_cashe,
           settings[:scale_margin] + settings[:scale_mark_size] / 2,
           y_coord_cashe)
    end
  end
end
