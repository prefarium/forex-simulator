# frozen_string_literal: true

require 'rspec'

# Метод скопирован из класса,
#   так как не представляется возможным вызвать его здесь
# (комментарии удалены, обращайтесь за ними в класс)
def handsome_step(amplitude)
  approx_step_size = amplitude / 5
  base_values      = [[10, 2], [20, 5], [25, 5], [50, 10], [100, 20]]
  power_difference = approx_step_size.digits.size - 2

  upd_values = base_values.map do |arr|
    arr.map! { |v| v * 10**power_difference }
    arr << (arr[0] - approx_step_size).abs
  end

  upd_values.reduce { |c, arr| arr[2] <= c[2] ? arr : c }[0..1]
end

describe 'handsome_step' do
  before(:all) do
    @steps =
      1_000.times.map { handsome_step(rand(50...2_000)) } +
      1_000.times.map { handsome_step(rand(2_000...1_000_000)) } +
      1_000.times.map { handsome_step(rand(1_000_000..1_000_000_000)) }
  end

  it 'should always return main step values which end by 0 or 5' do
    @steps.each { |n| expect(n[0].digits[0]).to eq(0) | eq(5) }
  end

  it 'should always return small step values which are 4 or 5 times less' \
     'than main step values' do
    @steps.each { |n| expect(n[0] / n[1]).to eq(4) | eq(5) }
  end

  it 'should return main step values which are 3 times or more' \
     'less than amplitude' do
    1000.times do |_n|
      amp = rand(50..10_000_000)
      expect(amp / handsome_step(amp)[0]).to be >= 3
    end
  end

  it 'should only return integers' do
    @steps.each { |a| a.each { |n| expect(n).to be_an Integer } }
  end
end
