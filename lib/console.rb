class Console
  def log(*args)
    p args.map(&:to_s).join(' ')
  end

  alias_method :error, :log
  alias_method :warn, :log
  alias_method :info, :log
  alias_method :trace, :log
end
