# frozen_string_literal: true

# Данный класс является родителем для каждого из элементов графика
class GraphImage < Magick::Draw
  class << self
    attr_reader :settings

    # Рассчитывает необхожимые для отрисовки параметры
    def take_and_process(settings)
      # История колебаний
      settings[:history]          = candles_unjson
      # Масимальное значение курса
      settings[:top_extremum]     = top_extremum(settings[:history])
      # Минимальное значение курса
      settings[:low_extremum]     = low_extremum(settings[:history])
      # Амплитуда колебаний
      settings[:amplitude]        = amplitude(settings)
      # Коэффицент увеличения элементов графика при его отрисовке
      settings[:scale_ratio]      = scale_ratio(settings)
      # Значение графика, которое соответствует нижней границе холста
      settings[:page_bottom]      = page_bottom(settings)
      # Значение графика, которое соответствует верхней границе холста
      settings[:page_top]         = page_top(settings)
      # Цены делений шкалы (шаги отметин на шкале)
      scale_step_cashe            = scale_step(settings[:amplitude])
      # Шаг отновных отметин
      settings[:scale_main_step]  = scale_step_cashe[0]
      # Шаг дополнительных отметин
      settings[:scale_small_step] = scale_step_cashe[1]
      # Перва метка, от которой отсчитываются остальные
      settings[:first_mark]       = find_first_mark(settings)

      @settings = settings
    end

    private

    # Возвращает историю колебаний курса, где все значения переведены
    #   в специальные единицы, используемые для отрисовки свечей
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

      JSON.parse(File.read("#{path}/../data/candles/minute_candles_db.json"))
          .transform_keys(&:to_i)
    end

    def top_extremum(history)
      history.map { |x| x[1][:max] }.max
    end

    def low_extremum(history)
      history.map { |x| x[1][:min] }.min
    end

    def amplitude(settings)
      amplitude = settings[:top_extremum] - settings[:low_extremum]
      # Принудительно выставляем диапазон колебаний в 1,
      #   если у нас уникальный случай, когда курс не колебался
      amplitude.zero? ? 1 : amplitude
    end

    def scale_ratio(settings)
      (settings[:image_height].to_f - settings[:vertical_padding] * 2
      ) / settings[:amplitude]
    end

    def page_top(settings)
      (settings[:top_extremum] +
          settings[:vertical_padding] / settings[:scale_ratio]
      ).floor
    end

    def page_bottom(settings)
      (settings[:low_extremum] -
          settings[:vertical_padding] / settings[:scale_ratio]
      ).ceil
    end

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
        # Ищем комфортные значения цен делений
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

    def find_first_mark(settings)
      (settings[:page_bottom]..).find do |x|
        (x % settings[:scale_main_step]).zero?
      end
    end
  end

  private

  # Метод переводит значения курса в значения на графике
  def to_graph(value, settings)
    ((settings[:top_extremum] - value) *
        settings[:scale_ratio] + settings[:vertical_padding]
    ).to_i
  end
end
