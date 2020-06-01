require 'rspec'

def handsome_step(amplitude)
  # предварительно-приблизительный шаг основных отметин шкалы
  approx_step_size = amplitude / 5

  # попарно: базовые образующие для шагов основных и меньших шагов шкалы
  base_values = [[10, 2], [20, 5], [25, 5], [50, 10], [100, 20]]

  # разность порядков базовых образующих и приблизительного шага шкалы
  power_difference = approx_step_size.digits.size - 2

  # приводим базу к порядку приблизительного шага и дополняем пары значением
  # удаленности приблизительного шага от каждого комфортного значения
  upd_values = base_values.map do |arr|
    arr.map! { |v| v = v * 10**power_difference }
    arr << (arr[0] - approx_step_size).abs
  end

  # ищем минимальную удаленность приблизительного шага от комфортного. если
  # попались два комфортных значения, до которых расстояние одинаково,
  # выбираем больший шаг и возвращаем основной и меньший шаги
  choice = upd_values.reduce { |c, arr| arr[2] <= c[2] ? arr : c }[0..1]
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


  it 'should always return small step values which are 4 or 5 times less' +
     'than main step values' do

    @steps.each { |n| expect(n[0] / n[1]).to eq(4) | eq(5) }
  end


  it 'should return main step values which are 3 times or more' +
     'less than amplitude' do

    1000.times do |n|
      amp = rand(50..10_000_000)
      expect(amp / handsome_step(amp)[0]).to be >= 3
    end
  end


  it 'should only return integers' do
    @steps.each { |a| a.each { |n| expect(n).to be_an Integer } }
  end
end
