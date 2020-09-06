# frozen_string_literal: true

class GraphWindow < Magick::ImageList
  def initialize
    super

    # Получаем готовые стандартыне настройки
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

    Candles.new.draw(self)
    LeftScale.new.draw(self)
  end

  private
    def read_settings
      current_path = File.dirname(__FILE__)
      # Парсим файл настроек с помощью регулярного выражения,
      #   чтобы получить настройки в виде пар ключ-значение
      doc = File.read(current_path + '/data/default_settings.xml')
                .scan(/
                       <(\w+)> # Открывающий тег
                        (\w+)  # Содержание тега
                       <\/\1>  # Закрывающий тег
                      /x)

      settings = {}

      # Полученный массив с парами настроек трансформируем в хеш
      # Регуляркой проверяем, является ли строка числом
      doc.each do |i|
        settings[i[0].to_sym] = i[1].match(/\A\d+\z/) ? i[1].to_i : i[1]
      end

      settings
    end
end

class GraphImage < Magick::Draw
  class << self
    attr_reader :settings

    # Метод рассчитывает необхожимые для отрисовки параметры
    def take_and_process(settings)
      settings[:history]          = candles_unjson
      settings[:top_extremum]     = top_extremum(settings[:history])
      settings[:low_extremum]     = low_extremum(settings[:history])
      settings[:amplitude]        = amplitude(settings)
      settings[:scale_ratio]      = scale_ratio(settings)
      settings[:page_bottom]      = page_bottom(settings)
      settings[:page_top]         = page_top(settings)
      scale_step_cashe            = scale_step(settings[:amplitude])
      settings[:scale_main_step]  = scale_step_cashe[0]
      settings[:scale_small_step] = scale_step_cashe[1]
      settings[:first_mark]       = find_first_mark(settings)

      @settings = settings
    end

    private
      # Возвращает историю колебаний курса, где все значения переведены
      #   в специальные единицы измерения, используемые для отрисовки свечей
      def candles_unjson
        history = rate_history

        history.each_key do |key|
          history[key].transform_keys!(&:to_sym).each_pair do |k, v|
            history[key][k] = currency_rate_to_graph_points(v)
          end
        end
      end

      def currency_rate_to_graph_points(value)
        (value * 10_000).round
      end

      def rate_history
        path = File.dirname(__FILE__)

        JSON.parse(File.read(path + '/data/candles/minute_candles_db.json'))
            .transform_keys(&:to_i)
      end

      # Максимальное значение курса
      def top_extremum(history)
        history.map { |x| x[1][:max] }.max
      end

      # Минимальное значение курса
      def low_extremum(history)
        history.map { |x| x[1][:min] }.min
      end

      def amplitude(settings)
        amplitude = settings[:top_extremum] - settings[:low_extremum]
        # Принудительно выставляем диапазон колебаний в 1,
        #   если у нас уникальный случай, когда курс не колебался
        amplitude.zero? ? 1 : amplitude
      end

      # Коэффицент увеличения элементов графика при его отрисовке
      def scale_ratio(settings)
        ( settings[:image_height].to_f - settings[:vertical_padding] * 2
        ) / settings[:amplitude]
      end

      # Значение верхней границы графика
      def page_top(settings)
        ( settings[:top_extremum] +
            settings[:vertical_padding] / settings[:scale_ratio]
        ).floor
      end

      # Значение нижней границы графика
      def page_bottom(settings)
        ( settings[:low_extremum] -
            settings[:vertical_padding] / settings[:scale_ratio]
        ).ceil
      end

      # Метод определяет цену деления шкалы (шаг отметин на шкале)
      #   в зависимости от амплитуды
      def scale_step(amplitude)
        case amplitude
        when 0..5
          [1, 1]
        when 6..12
          [2, 1]
        when 13..22
          [5, 1]
        when 23..49
          [10, 5]
        else
          # Ищем красивое значение цены деления, заданные заранее не подошли
          handsome_step(amplitude)
        end
      end

      def handsome_step(amplitude)
        # Предварительно-приблизительный шаг основных отметин шкалы
        approx_step_size = amplitude / 5

        # Попарно: базовые образующие для основных и меньших шагов шкалы
        base_values = [[10, 2], [20, 5], [25, 5], [50, 10], [100, 20]]

        # Разность порядков базовых образующих и приблизительного шага шкалы
        power_difference = approx_step_size.digits.size - 2

        # Приводим базу к порядку приблизительного шага
        #   и дополняем пары значением удаленности приблизительного шага
        #   от каждого комфортного значения
        upd_values = base_values.map do |arr|
          arr.map! { |v| v * 10**power_difference }
          arr << (arr[0] - approx_step_size).abs
        end

        # Ищем минимальную удаленность приблизительного шага от комфортного
        # Если попались два комфортных значения,
        #   до которых расстояние одинаково,
        #   выбираем больший шаг и возвращаем основной и меньший шаги
        upd_values.reduce { |c, arr| arr[2] <= c[2] ? arr : c }[0..1]
      end

      # Метод ищет точку на шкале, от которой начнём наносить отметки
      def find_first_mark(settings)
        (settings[:page_bottom]..).find do |x|
          (x % settings[:scale_main_step]).zero?
        end
      end
  end

  def initialize
    super
  end

  private
    def to_graph(value, settings)
      ( (settings[:top_extremum] - value) *
          settings[:scale_ratio] + settings[:vertical_padding]
      ).to_i
    end
end

class Candles < GraphImage
  def initialize
    super

    settings = GraphImage.settings

    stroke(settings[:candle_stroke])
    fill(settings[:candle_fill])
    stroke_width(settings[:candle_stroke_width])

    draw_candles(settings)
  end

  private
    def draw_candles(settings)
      settings[:start_date].step(settings[:finish_date], 60)
                           .with_index do |i, nth_candle|
        candle_cashe = {}

        set_candle_opacity(i, settings)

        draw_candle_body(i, nth_candle, settings, candle_cashe)
        draw_candle_shadows(i, nth_candle, settings, candle_cashe)
      end
    end

    def set_candle_opacity(idx, settings)
      if settings[:history][idx][:start] < settings[:history][idx][:finish]
        fill_opacity(settings[:up_candle_opacity])

      else
        fill_opacity(settings[:down_candle_opacity])
      end
    end

    def draw_candle_body(idx, nth_candle, settings, candle_cashe)
      candle_cashe[:start]  = to_graph(settings[:history][idx][:start],
                                       settings)
      candle_cashe[:finish] = to_graph(settings[:history][idx][:finish],
                                       settings)

      rectangle(nth_candle * settings[:density],
                candle_cashe[:start],
                nth_candle * settings[:density] + settings[:thickness],
                candle_cashe[:finish] + 1)
    end

    def draw_candle_shadows(idx, nth_candle, settings, candle_cashe)
      min = to_graph(settings[:history][idx][:min], settings)
      max = to_graph(settings[:history][idx][:max], settings)

      high_end = [candle_cashe[:start], candle_cashe[:finish]].min
      low_end  = [candle_cashe[:start], candle_cashe[:finish]].max
      middle   = nth_candle * settings[:density] + settings[:thickness] / 2

      line(middle, high_end, middle, max) if max != high_end

      line(middle, low_end + 1, middle, min) if min != low_end
    end
end

class LeftScale < GraphImage
  def initialize
    super

    settings = GraphImage.settings

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

    def mark_value(mark)
      mark = mark.to_s
      (5 - mark.size).times { mark.prepend('0') } if mark.size < 5
      mark.insert(-5, '.')
    end

    def draw_small_marks(settings)
      # Сокращение шапок итераторов
      first_mark = settings[:first_mark]
      top        = settings[:page_top]
      bottom     = settings[:page_bottom]
      step       = settings[:scale_small_step]

      # Отрисовка засечек вверх от первой (first_mark)
      first_mark.step(top, step) do |mark|
        if mark % settings[:scale_main_step]
          y_coord_cashe = to_graph(mark, settings)

          line(settings[:scale_margin],
              y_coord_cashe,
              settings[:scale_margin] + settings[:scale_mark_size] / 2,
              y_coord_cashe)
        end
      end

      # отрисовка засечек вниз от первой (first_mark)
      (first_mark - step).step(bottom, - step) do |mark|
        y_coord_cashe = to_graph(mark, settings)

        line(settings[:scale_margin],
            y_coord_cashe,
            settings[:scale_margin] + settings[:scale_mark_size] / 2,
            y_coord_cashe)
      end
    end
end
