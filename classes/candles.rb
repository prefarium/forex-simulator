# frozen_string_literal: true

# Класс, представляющий свечи
class Candles < GraphImage
  def initialize
    super

    settings = GraphImage.settings

    # Устанавливаем внешний вид свечи
    stroke(settings[:candle_stroke])
    fill(settings[:candle_fill])
    stroke_width(settings[:candle_stroke_width])

    draw_candles(settings)
  end

  private

  def draw_candles(settings)
    # Движемся по временному промежутку с шагом в 60 секунд
    # Для каждой временнОй отметки (timestamp)
    #   существует соответствующая свеча
    settings[:start_date].step(settings[:finish_date], 60)
                         .with_index do |timestamp, nth_candle|
      # Кэш служит для передачи результатов вычислений
      #   из draw_candle_body в draw_candle_shadows
      candle_cache = {}

      set_candle_opacity(timestamp, settings)

      draw_candle_body(timestamp, nth_candle, settings, candle_cache)
      draw_candle_shadows(timestamp, nth_candle, settings, candle_cache)
    end
  end

  # Во всех методах ниже конструкция settings[:history][timestamp] находит
  #   свечу по временнОй метке

  def set_candle_opacity(timestamp, settings)
    if settings[:history][timestamp][:start] <
       settings[:history][timestamp][:finish]
      fill_opacity(settings[:up_candle_opacity])

    else
      fill_opacity(settings[:down_candle_opacity])
    end
  end

  def draw_candle_body(timestamp, nth_candle, settings, candle_cache)
    candle_cache[:start]  = to_graph(settings[:history][timestamp][:start],
                                     settings)
    candle_cache[:finish] = to_graph(settings[:history][timestamp][:finish],
                                     settings)

    rectangle(nth_candle * settings[:density],
              candle_cache[:start],
              nth_candle * settings[:density] + settings[:thickness],
              candle_cache[:finish] + 1)
  end

  def draw_candle_shadows(timestamp, nth_candle, settings, candle_cache)
    min = to_graph(settings[:history][timestamp][:min], settings)
    max = to_graph(settings[:history][timestamp][:max], settings)

    # Для вычисления верхней границы тела свечи используется метод .min,
    #   так как гем rmagick создаёт холст с перевернутой системой координат,
    #   где точка (0;0) находится в левом верхнем углу
    # Аналогично с нижней границей
    high_end = [candle_cache[:start], candle_cache[:finish]].min
    low_end  = [candle_cache[:start], candle_cache[:finish]].max

    # Координаты середины свечи по горизонтали
    middle = nth_candle * settings[:density] + settings[:thickness] / 2

    line(middle, high_end,    middle, max) if max != high_end
    line(middle, low_end + 1, middle, min) if min != low_end
  end
end
