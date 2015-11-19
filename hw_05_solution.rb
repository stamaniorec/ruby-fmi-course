require 'digest/sha1'

class ObjectStore

  def self.init(&block)
    object_store = ObjectStore.new
    object_store.instance_eval(&block) if block_given?
    object_store
  end

  def add(name, object)
    stage << [name, object, 'add']
    ResponseWithResult.new("Added #{name} to stage.", true, object)
  end

  def commit(message)
    if stage.empty?
      Response.new("Nothing to commit, working directory clean.", false)
    else
      response_message = "#{message}\n\t#{stage.length} objects changed"
      commit = @branch_manager.active_branch.add_commit(message)
      ResponseWithResult.new(response_message, true, commit)
    end
  end

  def remove(name)
    object = @branch_manager.active_branch.get_object(name)
    if object
      stage << [name, object, 'remove']
      ResponseWithResult.new("Added #{name} for removal.", true, object)
    else
      Response.new("Object #{name} is not committed.", false)
    end
  end

  def checkout(commit_hash)
    commit = @branch_manager.active_branch.get_commit(commit_hash)
    if commit
      @branch_manager.active_branch.head = commit
      ResponseWithResult.new("HEAD is now at #{commit_hash}.", true, commit)
    else
      Response.new("Commit #{commit_hash} does not exist.", false)
    end
  end

  def branch
    @branch_manager
  end

  def log
    commits = @branch_manager.active_branch.commits.reverse
    if commits.empty?
      branch_name = @branch_manager.active_branch.name
      Response.new(
        "Branch #{branch_name} does not have any commits yet.",
        false
      )
    else
      Response.new(build_log(commits), true)
    end
  end

  def head
    head = @branch_manager.active_branch.head
    if head
      ResponseWithResult.new(head.message, true, head)
    else
      branch_name = @branch_manager.active_branch.name
      Response.new(
        "Branch #{branch_name} does not have any commits yet.",
        false
      )
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

  def stage
    @branch_manager.active_branch.stage
  end

  def build_log(commits)
    commits.map do |commit|
      "Commit #{commit.hash}\nDate: #{commit.formatted_date}" \
      "\n\n\t#{commit.message}\n\n"
    end.join.chomp.chomp
  end
end

class Commit
  attr_reader :objects, :hash, :date, :message

  def initialize(message, date, stage, head)
    @message = message
    @date = date
    @objects = fill_objects(stage, head)
    @hash = gen_hash
  end

  def formatted_date
    date.strftime("%a %b %d %H:%M %Y %z")
  end

  private
  def gen_hash
    Digest::SHA1.hexdigest("#{@date}#{@message}")
  end

  def fill_objects(stage, head)
    to_be_added, to_be_removed = partition(stage)
    objects = to_be_added.dup
    objects += non_removed_objects(head, to_be_removed)
  end

  def non_removed_objects(head, to_be_removed)
    head ? head.objects.reject { |obj| to_be_removed.include?(obj) } : []
  end

  def partition(stage)
    stage.partition { |item| item[2] == 'add' }.map do |group|
      group.map { |item| item.take(2) }
    end
  end
end

class Branch
  attr_reader :name, :stage
  attr_accessor :head

  def initialize(name, commits = [])
    @name = name
    @stage = []
    @commits = commits.dup
    @head = @commits.last
  end

  def add_commit(message)
    commit = Commit.new(message, Time.now, @stage, @head)
    @commits << commit
    @stage = []
    @head = @commits.last
  end

  def get_object(name)
    if head
      entry = head.objects.select { |object| object[0] == name }.first
      entry ? entry[1] : nil
    end
  end

  def commits
    head ? @commits.take_while { |commit| commit != head }.push(head) : []
  end

  def get_commit(commit_hash)
    @commits.select { |commit| commit.hash == commit_hash }.first
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
      commits_in_current_branch = @active_branch ? @active_branch.commits : []
      branch = Branch.new(branch_name, commits_in_current_branch)
      @branches[branch_name] = branch
      Response.new("Created branch #{branch_name}.", true)
    end
  end

  def set_active_branch(branch_name)
    @active_branch = @branches[branch_name]
  end

  def checkout(branch_name)
    if @branches.keys.include?(branch_name)
      set_active_branch(branch_name)
      Response.new("Switched to branch #{branch_name}.", true)
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
    list = @branches.sort.map do |name, _|
      name == active_branch.name ? "* #{name}\n" : "  #{name}\n"
    end.join.chomp
    Response.new(list, true)
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