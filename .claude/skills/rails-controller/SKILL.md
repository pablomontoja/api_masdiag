---
name: rails-controller
description: Creates Rails controllers with TDD approach - request spec first, then implementation. Use when creating new controllers, adding controller actions, implementing CRUD operations, or when user mentions controllers, routes, or API endpoints.
allowed-tools: Read, Write, Edit, Bash(bundle exec rspec:*), Glob, Grep
---

# Rails Controller Generator (TDD)

Creates RESTful controllers following project conventions with request specs first.

## Quick Start

1. Write failing request spec in `spec/requests/`
2. Run spec to confirm RED
3. Implement controller action
4. Run spec to confirm GREEN
5. Refactor if needed

## Project Conventions

This project uses:
- **Pundit** for authorization (`authorize @resource`, `policy_scope(Model)`)
- **Pagy** for pagination
- **Presenters** for view formatting
- **Multi-tenancy** via `current_account`
- **Turbo Stream** responses for dynamic updates

## TDD Workflow

### Step 1: Create Request Spec (RED)

```ruby
# test/requests/[resources]_test.rb
require 'test_helper'

class [Resources]Test < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "GET /[resources]" do
    resource = create(:resource, account: @user.account)
    other_resource = create(:resource, account: create(:user).account)

    get [resources]_path
    assert_response :success
    assert_select ".resource-name", text: resource.name
    refute_select ".resource-name", text: other_resource.name
  end

  test "GET /[resources]/:id" do
    resource = create(:resource, account: @user.account)

    get [resource]_path(resource)
    assert_response :success
  end

  test "POST /[resources]" do
    valid_params = { [resource]: attributes_for(:[resource]) }

    assert_difference '[Resource].count', 1 do
      post [resources]_path, params: valid_params
    end

    assert_redirected_to [resource]_path([Resource].last)
  end

  test "authorization returns 404 for unauthorized access" do
    other_resource = create(:resource, account: create(:user).account)

    get [resource]_path(other_resource)
    assert_response :not_found
  end
end
```

### Step 2: Run Test (Confirm RED)

```bash
bundle exec rails test test/requests/[resources]_test.rb
```

### Step 3: Implement Controller (GREEN)

```ruby
# app/controllers/[resources]_controller.rb
class [Resources]Controller < ApplicationController
  before_action :set_[resource], only: [:show, :edit, :update, :destroy]

  def index
    authorize [Resource], :index?
    @pagy, resources = pagy(policy_scope([Resource]).order(created_at: :desc))
    @[resources] = resources.map { |r| [Resource]Presenter.new(r) }
  end

  def show
    authorize @[resource]
    @[resource] = [Resource]Presenter.new(@[resource])
  end

  def new
    @[resource] = current_account.[resources].build
    authorize @[resource]
  end

  def create
    @[resource] = current_account.[resources].build([resource]_params)
    authorize @[resource]

    if @[resource].save
      redirect_to [resources]_path, notice: "[Resource] created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @[resource]
  end

  def update
    authorize @[resource]

    if @[resource].update([resource]_params)
      redirect_to @[resource], notice: "[Resource] updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @[resource]
    @[resource].destroy
    redirect_to [resources]_path, notice: "[Resource] deleted successfully"
  end

  private

  def set_[resource]
    @[resource] = policy_scope([Resource]).find(params[:id])
  end

  def [resource]_params
    params.require(:[resource]).permit(:name, :field1, :field2)
  end
end
```

### Step 4: Run Spec (Confirm GREEN)

```bash
bundle exec rspec spec/requests/[resources]_spec.rb
```

## Namespaced Controllers

For nested routes like `settings/accounts`:

```ruby
# app/controllers/settings/accounts_controller.rb
module Settings
  class AccountsController < ApplicationController
    before_action :set_account

    def show
      authorize @account
    end

    private

    def set_account
      @account = current_account
    end
  end
end
```

## Turbo Stream Response Pattern

```ruby
def create
  @resource = current_account.resources.build(resource_params)
  authorize @resource

  if @resource.save
    respond_to do |format|
      format.html { redirect_to resources_path, notice: "Created" }
      format.turbo_stream do
        flash.now[:notice] = "Created"
        @pagy, @resources = pagy(policy_scope(Resource).order(created_at: :desc))
        render turbo_stream: [
          turbo_stream.replace("resources-list", partial: "resources/list"),
          turbo_stream.update("modal", "")
        ]
      end
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Checklist

- [ ] Request spec written first (RED)
- [ ] Multi-tenant isolation tested
- [ ] Authorization tested (404 for unauthorized)
- [ ] Controller uses `authorize` on every action
- [ ] Controller uses `policy_scope` for queries
- [ ] Presenter wraps models for views
- [ ] Strong parameters defined
- [ ] All tests GREEN
