require 'readline'

class String
  def remove_backslash_comments
    self.gsub(/\\.*/, '')
  end
end

class Waltz
  attr_accessor :runtime_stack, :runtime_words,
                :control_stack, :control_words,
                :compiled

  def initialize
    @runtime_stack = []
    @control_stack = []
    @compiled = []

    @runtime_words = {
      '+' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a + b)
      },

      '*' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a * b)
      },

      '-' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a - b)
      },

      '/' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a / b)
      },

      '=' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a == b)
      },

      '>' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a > b)
      },

      '<' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push (a < b)
      },

      'swap' => -> {
        a, b = @runtime_stack.pop(2)
        @runtime_stack.push b, a
      },

      'dup' => -> {
        @runtime_stack.push @runtime_stack.last
      },

      'drop' => -> {
        @runtime_stack.pop
      },

      'over' => -> {
        @runtime_stack.push @runtime_stack[-2]
      },

      '..' => -> {
        puts "stack: #{@runtime_stack.inspect}"
      },

      '.' => -> {
        p @runtime_stack.pop
      }
    }

    @control_words = {
      ':' => -> {
        if @control_stack.empty?
          @control_stack.push ":"
        else
          raise ": inside control stack: #{@control_stack}"
        end
      },

      ';' => -> {
        unless @control_stack.first == ":"
          raise ": not balanced with ; in control stack: #{@control_stack}"
        end

        word, *body = @control_stack[1..-1]

        unless word
          raise "Unnamed word definition in control stack: #{@control_stack}"
        end

        @runtime_words[word] = body
        @control_stack = []
      }
    }
  end

  def state
    [@runtime_stack.dup, @control_stack.dup, @compiled.dup]
  end

  def load_state state
    runtime_stack, control_stack, compiled = state
    @runtime_stack = runtime_stack
    @control_stack = control_stack
    @compiled = compiled
  end

  def compile line
    words = line.remove_backslash_comments.split

    words.each do |word|
      control_action = @control_words[word]
      runtime_action = @runtime_words[word]

      if @control_stack.first == ":"
        if @control_stack.count == 1
          if control_action or runtime_action
            raise "#{word} is already defined."
          else
            @control_stack.push word # name of new word
            next
          end
        else
          current_stack = @control_stack
        end
      else
        current_stack = @compiled
      end

      if control_action
        control_action.call
      elsif runtime_action
        if runtime_action.is_a? Array
          # do dynamic lookup for now
          current_stack.push -> { run_word word }
        else
          current_stack.push runtime_action
        end
      else
        if /(0|[1-9]\d*)\.\d+/ =~ word
          current_stack.push -> { @runtime_stack.push word.to_f }
        elsif /0|[1-9]\d*/ =~ word
          current_stack.push -> { @runtime_stack.push word.to_i }
        else
          # assume word will be defined by the time it's run
          current_stack.push -> { run_word word }
        end
      end
    end
  end

  def run_word word
    runtime_action = @runtime_words[word]
    if runtime_action.is_a? Proc
      runtime_action.call
    elsif runtime_action.is_a? Array
      runtime_action.each { |action| action.call }
    elsif runtime_action.is_a? NilClass
      raise "Undefined word: #{word}"
    else
      raise "Unexpected runtime word type #{word}: #{word.class}"
    end
  end

  def run
    @compiled.each do |action|
      action.call
    end
  ensure
    @compiled = []
  end

  def compile_and_run line
    compile line
    if @control_stack.empty?
      run
    else
      raise "Control stack not empty: #{@control_stack.inspect}"
    end
  end

  def repl
    prompt = 'waltz> '
    while line = Readline.readline(prompt, true)
      save_state = state
      begin
        compile line
        if @control_stack.empty?
          run
          prompt = 'waltz> '
        else
          prompt = '   ... '
        end
      rescue => e
        p e
        load_state(save_state)
      end
    end
  end
end

