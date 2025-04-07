# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Setup and Running
- Setup: `bin/setup`
- Start server: `bin/rails server` or `bin/dev`
- Background jobs: `bin/rails solid_queue:work`

### Tests
- Run all tests: `bin/rails test`
- Run single test: `bin/rails test TEST=test/models/ride_test.rb:42` (where 42 is line number)
- System tests: `bin/rails test:system`

### Linting and Static Analysis
- Run RuboCop: `bin/rubocop`
- Fix auto-correctable issues: `bin/rubocop -a`
- Security scanning: `bin/brakeman`

## Code Style Guidelines

- Ruby version: 3.2.1
- Rails follows Rubocop Rails Omakase style guide
- Use 2 spaces for indentation
- Prefer single quotes for strings unless interpolation is needed
- Use snake_case for methods, variables and file names
- Use CamelCase for classes and modules
- Follow Rails conventions for controller/model organization
- Organize JavaScript in app/javascript/controllers using Stimulus
- UI uses Tailwind CSS for styling
- Include appropriate error handling with clear error messages