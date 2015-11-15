require 'digest/sha1'

class ObjectStore

  def self.init
    if block_given?
      # todo
    end
    ObjectStore.new
  end

  def branch
    @branch_manager
  end

  def add(name, object)
    @branch_manager.active_branch.stage << [name, object, 'add']
    ResponseWithResult.new("Added #{name} to stage.", true, object)
  end

  def commit(message)
    if @branch_manager.active_branch.stage.size == 0
      Response.new("Nothing to commit, working directory clean.", false)
    else
      # c = Commit.new(message, Time.new, @branch_manager.active_branch.stage)
      # @branch_manager.active_branch.add_commit(c)
      @branch_manager.active_branch.add_commit(message)
      # add c to current branch
      # @branch_manager.active_branch.stage.each { |k,v| p "#{k} -> #{v}" }
      count = @branch_manager.active_branch.stage.size
      @branch_manager.active_branch.clear_stage
      Response.new("#{message}\n\t#{count} objects changed", true)
      # 
    end
  end
  
  def remove(name)
    unless @branch_manager.active_branch.has_object?(name)
      Response.new("Object #{name} is not committed.", false)
    else
      # @stage.delete(name)
      #TODO brainfart cur branch remove object name
      object = @branch_manager.active_branch.get_object(name)
      # p "! #{object}"
      @branch_manager.active_branch.stage << [name, object, 'remove']
      # p @branch_manager.active_branch.stage
      ResponseWithResult.new("Added #{name} for removal.", true, object)
    end
  end
  
  def checkout(commit_hash)
    # p '!!!'
    #   p @branch_manager.active_branch.commits.any? { |commit| p commit.hash; commit.hash == commit_hash }
    #   p commit_hash
    # p '!!!'
    if @branch_manager.active_branch.all_commits.any? { |commit| commit.hash == commit_hash }
      foo = @branch_manager.active_branch.all_commits.select { |commit| commit.hash == commit_hash }.first
      # p foo
      @branch_manager.active_branch.head = foo
      # p @branch_manager.active_branch.head
      # p 'hi'
      ResponseWithResult.new("HEAD is now at #{commit_hash}.", true, foo)
    else
      Response.new("Commit #{commit_hash} does not exist.", false)
    end
  end

  def log
    if @branch_manager.active_branch.commits.length == 0
      Response.new("Branch #{@branch_manager.active_branch.name} does not have any commits yet.", false)
    else
      res = ""
      @branch_manager.active_branch.commits.reverse.each do |commit|
        # p commit
        res += "Commit #{commit.hash}\nDate: #{commit.timestamp}\n\n\t#{commit.message}\n\n"
      end
      # res
      Response.new(res, true)
    end
  end

  def head
    commits = @branch_manager.active_branch.commits
    if commits.length == 0
      Response.new("Branch #{@branch_manager.active_branch.name} does not have any commits yet.", false)
    else
      result = @branch_manager.active_branch.head
      ResponseWithResult.new(result.message, true, result)
    end
  end

  def get(name)
    obj = @branch_manager.active_branch.get_object(name)
    if obj
      ResponseWithResult.new("Found object #{name}.", true, obj)
    else
      Response.new("Object #{name} is not committed.", false)
    end
  end



  private
  def initialize
    @branch_manager = BranchManager.new
    @branch_manager.create('master')
    @branch_manager.set_active_branch('master')
  end
end

class Commit
  attr_reader :objects, :hash, :timestamp, :message
  def initialize(message, timestamp, stage, head)
    @message = message
    @timestamp = timestamp.strftime("%a %b %d %H:%M %Y %z")
    # p '!'
    # p stage.partition { |item| item[2] == 'add' }.map { |group| group.map { |item| p item; item.take(2)} }
    to_be_added, to_be_removed = stage.partition { |item| item[2] == 'add' }.map { |group| group.map { |item| item.take(2)} }
    # p to_be_added
    # p to_be_removed
    @objects = []
    @objects += to_be_added
    if head 
      head.objects.each do |obj|
        @objects << obj unless to_be_removed.include?(obj)
      end
    end
    # to_be_removed.each { |del_me| }
    # p @objects
    # stage.each do |item|

    # end
    
    # p objects
    # @objects = objects.dup.map { |item| item.take(2) if item[2] == 'add' }
    # @objects = []
    # objects.each { |obj| @objects << obj.take(2) if obj[2] == 'add'}
    # p @objects
    @hash = gen_hash
  end
  def gen_hash
    "#{@message}"
    # Digest::SHA1.hexdigest "#{@timestamp}#{@message}"
  end
  def date
    @timestamp
  end
end

class Branch
  attr_reader :name, :stage, :head
  attr_writer :head

  def initialize(name, commits = [])
    @name = name
    @stage = []
    @commits = commits.dup
    @head = @commits.last
  end
  def add_commit(message)
    c = Commit.new(message, Time.now, @stage, @head)
    # c = commit.dup
    # last = @commits.last
    # if last
    #   last.objects.each { |obj| c.objects << obj if c.objects.include?(obj) }
    # end
    # c = (c & @head.co)
    @commits << c
    @head = @commits.last
  end
  def has_object?(name)
    # p @commits
    head.objects.any? { |object| object.first == name } # @commits.any? { |commit| commit.objects.any? { |object| object.first == name } }
  end
  def get_object(name)
    # p "get object #{name}"
    return nil unless head
    head.objects.each { |obj| return obj[1] if obj[0] == name }
    # @commits.take_while { |commit| commit != head }.push(head).last.objects.each { |obj| p obj[0]; p name; return obj[1] if obj[0] == name }
    nil
    # p 'wtf'
  end
  def clear_stage
    @stage = []
  end
  def commits
    a = @commits.take_while { |commit| commit != head }
    a.push(head) if head
    a
  end
  def all_commits
    @commits
  end
end

class BranchManager
  attr_reader :active_branch

  def initialize
    @branches = {}
  end

  def create(branch_name)
    if @branches.keys.include?(branch_name)
      Response.new("Branch #{branch_name} already exists.", false)
    else
      b = Branch.new(branch_name, @active_branch ? @active_branch.commits : [])
      @branches[branch_name] = b
      Response.new("Created branch #{branch_name}.", true)
    end
  end
  def set_active_branch(branch_name)
    @active_branch = @branches[branch_name]
  end
  def checkout(branch_name)
    if @branches.keys.include?(branch_name)
      set_active_branch(branch_name)
      Response.new("Switched to branch #{branch_name}", true)
    else
      Response.new("Branch #{branch_name} does not exist.", false)
    end
  end
  def remove(branch_name)
    if @branches.keys.include?(branch_name)
      if branch_name == active_branch.name
        Response.new("Cannot remove current branch.", false)
      else
        @branches.delete(branch_name)
        Response.new("Removed branch #{branch_name}.", true)
      end
    else
      Response.new("Branch #{branch_name} does not exist.", false)
    end
  end
  def list
    res = ""
    @branches.sort.each do |name, branch|
      if name == active_branch.name
        res += "* #{name}\n"
      else
        res += "  #{name}\n"
      end
    end
    res
  end
end

class Response
  attr_reader :message
  def initialize(message, status)
    @message = message
    @status = status
  end
  def success?
    @status
  end
  def error?
    not success?
  end
end

class ResponseWithResult < Response
  attr_reader :result
  def initialize(message, status, result)
    super(message, status)
    @result = result
  end
end

# repo = ObjectStore.init

# # repo.add("important", "This is my first version.")
# # repo.add("important", "f")
# # repo.add("a", "f")

# r = repo.add("a", "content")
# p r
# r = repo.commit("commited a")
# p r
# r = repo.remove("a")
# p r
# r = repo.commit("removed a")
# p r
# # r = repo.checkout()
# # p repo.branch.active_branch.commits
# # p repo.branch.active_branch.head
# # r = repo.checkout("commited a")
# # p r 
# # p repo.branch.active_branch.head

# r = repo.branch.create('develop')
# p r
# r = repo.branch.create('develop')
# p r
# p repo.branch.active_branch.name
# # r = repo.branch.checkout('develop')
# p r
# p repo.branch.active_branch.name

# repo.branch.create('aa')
# p '---------'
# p repo.branch.instance_variable_get('@branches').keys
# # r = repo.branch.remove('develop')
# p r
# p repo.branch.instance_variable_get('@branches').keys
# puts repo.branch.list

# p '~~~~~~~~~~~~~~'
# repo = ObjectStore.init
# repo.add('foo1', :bar1)
# # repo.commit('First commit')

# repo.add('foo2', :bar2)
# # repo.commit('Second commit')
# puts repo.log.message
# p repo.branch.active_branch.instance_variable_get('@stage')

# p '!!!!!!!!!!!!!!!!'
repo = ObjectStore.init

p repo.add('answer', 42);
p repo.commit('Add the answer')

p repo.add('the_question', :unknown)
p repo.remove('answer')
p repo.commit('Add the question, remove the answer')

p repo.checkout('Add the answer')

p repo.get('the_question')
p repo.get('answer')

puts repo.log.message

p repo.head

p repo.checkout('Add the question, remove the answer')
p repo.head
puts repo.log.message

# # r = repo.checkout('Add the answer')
# # p r
# puts repo.log.message
# p repo.get('the_question')