module EnvTestHelper
  # Sets environment variables for the block and puts the old values back.
  def with_env(vars)
    previous = vars.to_h { |key, _| [ key, ENV[key] ] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
