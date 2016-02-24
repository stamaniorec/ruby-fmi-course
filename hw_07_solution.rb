module LazyMode
  class Date
    attr_reader :year, :month, :day, :date_string

    def initialize(date_string)
      @date_string = date_string
      @year, @month, @day = date_string.split('-').map(&:to_i)
    end

    alias_method :to_s, :date_string

    def add_day
      @day += 1

      if @day > 30
        @day = 1
        add_month
      end

      construct_new
    end

    def add_month
      @month += 1

      if @month > 12
        @month = 1
        @year += 1
      end

      construct_new
    end

    def add_week
      7.times { add_day }
      construct_new
    end

    private
    def construct_new
      Date.new("#{@year.to_s.rjust(4, '0')}-#{@month.to_s.rjust(2, '0')}-"\
              "#{@day.to_s.rjust(2, '0')}")
    end
  end

  class NoteBuilder
    def initialize(header, tags, file_name, &block)
      @header = header
      @tags = tags
      @file_name = file_name
      @sub_notes = []
      instance_eval(&block)
    end

    def status(value)
      @status = value
    end

    def body(value)
      @body = value
    end

    def scheduled(date)
      @scheduled, @repeat = date.split
    end

    def note(header, *tags, &block)
      note = Note.new(header, tags, @file_name, &block)
      @sub_notes << note
      note
    end

    def build
      set_defaults
      self
    end

    private
    def set_defaults
      @status ||= :topostpone
      @body ||= ''
    end
  end

  class Repeater
    def initialize(start_date, period, frequency)
      @date = Date.new(start_date)
      @method_name = ('add_' + period).to_sym
      @frequency = frequency
    end

    def repeats_before(date)
      while @date.to_s <= date.to_s
        yield @date
        increment_date
      end
    end

    private
    def increment_date
      @frequency.to_i.times { @date = @date.public_send(@method_name) }
    end
  end

  class Note
    attr_reader :header, :body, :status, :tags, :file_name, :sub_notes

    def initialize(header, tags, file_name, &block)
      note_builder = NoteBuilder.new(header, tags, file_name, &block).build

      note_builder.instance_variables.each do |instance_variable|
        value = note_builder.instance_variable_get(instance_variable)
        instance_variable_set(instance_variable, value)
      end
    end

    def repeats(date)
      number, repeater, scale = @repeat.chars.drop(1)
      case repeater
        when 'd' then scale = 'day'
        when 'w' then scale = 'week'
        when 'm' then scale = 'month'
      end
      Repeater.new(@scheduled, scale, number).enum_for(:repeats_before, date)
    end

    def scheduled?(date)
      @repeat ? scheduled_repeat?(date) : (date.to_s == @scheduled)
    end

    private
    def scheduled_repeat?(date)
      repeats(date).any? { |repeat| repeat.to_s == date.to_s }
    end
  end

  class Agenda
    attr_accessor :notes

    def where(**kwargs)
      copy = clone
      notes = filter_by_tag(copy.notes, kwargs[:tag])
      notes = filter_by_text(notes, kwargs[:text])
      notes = filter_by_status(notes, kwargs[:status])
      copy.notes = notes
      copy
    end

    def filter_by_tag(notes, tag)
      return notes unless tag
      notes.select { |note| note.tags.include?(tag) }
    end

    def filter_by_text(notes, text)
      return notes unless text
      notes.select { |note| note.header =~ text }
    end

    def filter_by_status(notes, status)
      return notes unless status
      notes.select { |note| note.status == status }
    end

    private
    def get_all_notes(list_of_notes)
      notes = []
      queue = list_of_notes.clone
      until queue.empty?
        notes << queue.first
        add_sub_notes(queue, queue.shift)
      end
      notes
    end

    def add_sub_notes(queue, note)
      note.sub_notes.each do |sub_note|
        queue << sub_note
      end
    end

    def add_if_scheduled_for_day(note, day)
      if note.scheduled?(day)
        @notes << build_agenda_item(note, day)
      end
    end

    def build_agenda_item(note, date)
      item = note.clone
      item.define_singleton_method(:date) do
        date
      end
      item
    end
  end

  class DailyAgenda < Agenda
    def initialize(date, notes)
      @notes = []
      @date = date

      get_all_notes(notes).each do |note|
        add_if_scheduled_for_day(note, date)
      end
    end

    def where
    end
  end

  class WeeklyAgenda < Agenda
    def initialize(date, notes)
      @notes = []
      @week = get_week(date)
      @date = date

      get_all_notes(notes).each do |note|
        add_if_scheduled_for_week(note)
      end
    end

    def add_if_scheduled_for_week(note)
      @week.each do |day|
        add_if_scheduled_for_day(note, day)
      end
    end

    private
    def get_week(date)
      7.times.each_with_object([]) do |_, week|
        week << date
        date = date.add_day
      end
    end
  end

  class File
    attr_reader :name, :notes

    def initialize(file_name)
      @name = file_name
      @notes = []
    end

    def note(header, *tags, &block)
      note = Note.new(header, tags, @name, &block)
      @notes << note
      note
    end

    def daily_agenda(date)
      DailyAgenda.new(date, @notes)
    end

    def weekly_agenda(date)
      WeeklyAgenda.new(date, @notes)
    end
  end

  def self.create_file(file_name, &block)
    file = File.new(file_name)
    file.instance_eval(&block)
    file
  end
end