class WrapperActor
  include Celluloid::IO
  execute_block_on_receiver :wrap

  def wrap
    yield
  end
end

def with_wrapper_actor
  WrapperActor.new
end
