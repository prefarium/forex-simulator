# frozen_string_literal: true


def to_points(rate_value)
  (rate_value * 10_000).round
end


def handsome_round(amplitude)
  number = amplitude / 5
  arr    = number.digits.reverse

  if (3..7).any?(arr[1])
    arr[1] = 5

  elsif (0..2).any?(arr[1])
    arr[1] = 0

  else
    arr[0] += 1
    arr[1]  = 0
  end

  (2...arr.size).each { |i| arr[i] = 0 }

  arr.join('').to_i
end


def scale_step(amplitude)
  case amplitude
  when 0..5
    1
  when 6..12
    2
  when 13..45
    10
  when 46..90
    20
  when 91..110
    25
  when 111..180
    40
  when 181..270
    50
  when 271..320
    75
  when 321...650
    100
  else
    handsome_round(amplitude)
  end
end
