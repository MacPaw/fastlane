RSpec::Matchers.define(:a_configuration_matching) do |expected|
  match do |actual|
    if actual.values.kind_of?(Hash) && expected.values.kind_of?(Hash)
      puts "#{actual.values.sort.to_h} != #{expected.values.sort.to_h}" if actual.values.sort.to_h != expected.values.sort.to_h
      actual.values.sort.to_h == expected.values.sort.to_h
    else
      return actual.values == expected.values
    end
  end
end

def before_each_match
  ENV["DELIVER_USER"] = "flapple@krausefx.com"
  ENV["DELIVER_PASSWORD"] = "so_secret"
end
