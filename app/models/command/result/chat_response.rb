class Command::Result::ChatResponse
  attr_reader :command_lines, :context_url

  def initialize(context_url: nil, command_lines:)
    @context_url = context_url
    @command_lines = command_lines
  end

  def has_context_url?
    context_url.present?
  end
end
