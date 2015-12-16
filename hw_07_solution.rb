module LazyMode
  class Date
    attr_reader :year, :month, :day, :date_string

    def initialize(date_string)
      @date_string = date_string
      @year, @month, @day = date_string.split('-').map(&:to_i)
    end

    alias_method :to_s, :date_string
  end

  class Note
    attr_accessor :header, :file_name, :body, :status, :tags
#header - връща низ - заглавие на бележката ни
#file_name - връща низ - име на файла, в който пазим бележката
#body - връща низ - текстово съдържание на нашата бележка
#status - връща един от следните два символа - :topostpone, :postponed
#tags - връща масив с всички тагове за бележката, а в случай че няма такива - връща празен масив
    def initialize(header, tags, &block)
      @header = header
      @tags = tags
      instance_eval(&block)
      # @attributes = {}
    end
    def method_missing(name, *args, &block)
      p self.methods - Object.methods
      p respond_to?(name)
      p *args
      # send((name.to_s+'=').to_sym, args)
      # self.send(name)
      # p name.class
      # p ('@'+name/)
      # self.instance_variable_set(('@'+name), *args)
      p self
      # self.send(name, *args)
      p "called for #{name}"
      # attributes[name] = args.first
    end
  end

  class File
    # #name
    # #notes
  end

  def self.create_file(file_name, &block)
    # note
    instance_eval(&block)
    p 'a'
    # return a LazyMode::File
  end

  private
  def self.note(header, *tags, &block)
    Note.new(header, tags, &block)
    # f = Note.new
    # f = NoteFactory.new
    # f.instance_eval(&block)

    # p 'b'
    # instance_eval(&block)
    # creates new note
  end

  def scheduled()

  end
end

file = LazyMode.create_file('work') do
  note 'sleep', :important, :wip do
    scheduled '2012-08-07'
    # status :postponed
    # body 'Try sleeping more at work'
  end


  note 'useless activity' do
    # scheduled '2012-08-07'
  end
end

# file.name                  # => 'work'
# file.notes.size            # => 2
# file.notes.first.file_name # => 'work'
# file.notes.first.header    # => 'sleep'
# file.notes.first.tags      # => [:important, :wip]
# file.notes.first.status    # => :postponed
# file.notes.first.body      # => 'Try sleeping more at work'
# file.notes.last.file_name  # => 'work'
# file.notes.last.header     # => 'useless activity'
# file.notes.last.tags       # => []
# file.notes.last.status     # => :topostpone