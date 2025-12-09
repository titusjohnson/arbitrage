# Resources - Rails 8 Application

## Project Overview

Resources is a Rails 8 application built with modern conventions and best practices.

## Technology Stack

- **Framework**: Rails 8.0.4
- **Ruby**: 3.3.4
- **Database**: SQLite3
- **Frontend**: 
  - Hotwire (Turbo & Stimulus)
  - ImportMap for JavaScript
  - Sass for stylesheets (no CSS framework)
- **Authentication**: Rails 8 built-in authentication generator
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Deployment**: Kamal 2.9.0

## Key Features

### Authentication System
The application uses Rails 8's built-in authentication system, which includes:
- User model with email/password authentication
- Session management
- Password reset functionality
- Secure password handling with bcrypt

### Database Structure
- **Users Table**: Stores user accounts with email_address and password_digest
- **Sessions Table**: Manages user sessions with IP address and user agent tracking

## Development Setup

### Prerequisites
- Ruby 3.3.4
- Rails 8.0.4
- SQLite3
- Homebrew (for macOS dependencies)

### Getting Started
```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Start the development server
bin/dev
```

## Project Structure

### Models
- `app/models/user.rb` - User authentication model
- `app/models/session.rb` - Session management model
- `app/models/current.rb` - Current user/session context

### Controllers
- `app/controllers/application_controller.rb` - Base controller with authentication
- `app/controllers/sessions_controller.rb` - Session management (login/logout)
- `app/controllers/passwords_controller.rb` - Password reset functionality
- `app/controllers/concerns/authentication.rb` - Authentication concern

### Views
- `app/views/sessions/` - Login views
- `app/views/passwords/` - Password reset views
- `app/views/passwords_mailer/` - Password reset email templates

## Rails Conventions

This project follows Rails 8 conventions:
- RESTful routing patterns
- Convention over configuration
- Fat models, skinny controllers
- Hotwire for modern frontend interactions
- Progressive enhancement

## Working with Claude

When working on this project with Claude, please:
1. Follow Rails 8 conventions and best practices
2. Use built-in Rails features before adding gems
3. Keep the codebase simple and maintainable
4. Test changes thoroughly
5. Prefer Hotwire/Turbo over heavy JavaScript frameworks
6. Use Stimulus controllers for interactive components

## Testing

The project uses Rails' default testing framework (Minitest):
```bash
# Run all tests
bin/rails test

# Run system tests
bin/rails test:system
```

## Code Quality

- **Brakeman**: Security scanning (`bin/brakeman`)
- **Rubocop**: Code style linting (`bin/rubocop`)

## Deployment

This application is configured for deployment with Kamal 2.9.0.

## Resources

- [Rails 8 Guides](https://guides.rubyonrails.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Turbo Documentation](https://turbo.hotwired.dev/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
