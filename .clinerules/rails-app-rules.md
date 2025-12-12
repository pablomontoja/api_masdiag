# Brief overview
This document outlines the development and debugging guidelines for API-only applications.

You are an expert in Ruby on Rails API, MySQL, background jobs, and API integration patterns.

## CLI command rules
 don't run `rails s` or `rails server`
 if you want to use `rails` command use `rvm use 3.3.7 &&` just before `rails`

## Development Tech Stack and Workflow
 **Application Mode:** Rails API-only mode (generated with `--api` flag).
 **Containerization:** Docker is the standard for setting up development and production environments. Use Docker Compose to orchestrate the Rails and MySQL services.
 **Database:** Use MySQL as the database for all environments.
   - *Database Adapter:* Use the `mysql2` gem for MySQL interaction.
 **Testing:** Use `Rspec` for testing the Ruby on Rails API application.

## Architectural Choices & External Integration
 **API Architecture:** Rails serves as a RESTful JSON API backend.
 **HTTP Client/API Client:** Use the `faraday` gem for making RESTful API calls.
 **Asynchronous Processing:** For long-running tasks like file parsing or data analysis, use `solid_queue`.
 **API Versioning:** Implement versioning using namespaced routes (e.g., `/api/v1/`).

## Code Style and Structure
 Write concise, idiomatic Ruby code with accurate examples.
 Follow Rails API conventions and best practices.
 Use object-oriented and functional programming patterns as appropriate.
 Prefer iteration and modularization over code duplication.
 Use descriptive variable and method names (e.g., authenticated?, calculate_total).
 Structure files according to Rails API conventions (controllers in `api/` namespace, serializers, etc.).

## Naming Conventions
 Use snake_case for file names, method names, and variables.
 Use CamelCase for class and module names.
 Follow Rails naming conventions for models, controllers, and serializers.
 Namespace API controllers under `Api::V1::` or similar.

## Ruby and Rails Usage
 Use Ruby 3.x features when appropriate (e.g., pattern matching, endless methods).
 Leverage Rails' built-in helpers and methods.
 Use ActiveRecord effectively for database operations.
 Inherit API controllers from `ActionController::API` instead of `ActionController::Base`.

## Syntax and Formatting
 Follow the Ruby Style Guide (https://rubystyle.guide/)
 Use Ruby's expressive syntax (e.g., unless, ||=, &.)
 Prefer single quotes for strings unless interpolation is needed.

## Error Handling and Validation
 Use exceptions for exceptional cases, not for control flow.
 Implement proper error logging and structured JSON error responses.
 Use ActiveModel validations in models.
 Handle errors gracefully in controllers and return appropriate HTTP status codes with JSON error messages.
 Use `rescue_from` in ApplicationController for consistent error handling.
 Use Sentry to send errors for application monitoring (e.g., `Sentry.capture_exception(e)`)
 Return standardized error response format:

   ```json
   {
      "message": "Bad authentication credentials"
   }
   ```

## API Response Format
 Use JSON as the primary response format.
 Implement serializers (use `Alba JSON serializer (https://github.com/okuramasafumi/alba)`) for consistent response structure.
 Follow JSON:API specification or similar standards for response formatting.
 Include proper HTTP status codes (200, 201, 204, 400, 401, 403, 404, 422, 500, etc.).
 Implement pagination for collection endpoints using `pagy` gem.

## Performance Optimization
 Use database indexing effectively.
 Implement caching strategies (Rails cache, Redis).
 Use eager loading to avoid N+1 queries.
 Optimize database queries using includes, joins, or select.
 Use database connection pooling appropriately.

## Key Conventions
 Follow RESTful routing conventions.
 Use concerns for shared behavior across models or controllers.
 Implement service objects for complex business logic.
 Use background jobs (`solid_queue`) for time-consuming tasks.
 Keep controllers thin; move business logic to models, services, or concerns.
 Use strong parameters for input validation.

## Testing
 Do not include testing in your implementation planning unless I ask you to.
 Write comprehensive tests using Rspec.
 Follow TDD/BDD practices.
 Use factories (FactoryBot) for test data generation.
 Test API endpoints for various scenarios (success, validation errors, authentication failures).
 Test JSON response structure and content.

## Security
 Use strong parameters in controllers.
 Protect against common web vulnerabilities (SQL injection, mass assignment).
 Implement rate limiting (e.g., `rack-attack` gem).
 Use CORS appropriately with `rack-cors` gem.
 Validate and sanitize all input data.
 Use HTTPS in production.
 Implement request authentication for all protected endpoints.

## API Documentation
 Consider documenting APIs using `oas_rails (https://github.com/a-chacon/oas_rails)`.
 Keep API documentation up-to-date with implementation.

Follow the official Ruby on Rails guides for best practices in routing, controllers, models, and other Rails API components.