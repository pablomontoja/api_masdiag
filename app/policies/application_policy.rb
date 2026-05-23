class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def new?     = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} is missing a #resolve method."
    end

    private

    attr_reader :user, :scope
  end
end
