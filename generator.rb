# frozen_string_literal: true

require 'json'


rate   = {}
dollar = 75.0
euro   = 82.0


1_589_749_200.step(1_589_752_200, 60) do |i|
  minute_history = []

  60.times do
    dollar = (dollar + rand(-0.02..0.02)).round(4)
    euro   = (euro   + rand(-0.02..0.02)).round(4)

    minute_history << (euro / dollar).round(4)
  end

  rate[i] = { 'start'  => minute_history[0],
              'finish' => minute_history[-1],
              'max'    => minute_history.max,
              'min'    => minute_history.min }
end


File.write('data/candles/minute_candles_db.json', rate.to_json)
