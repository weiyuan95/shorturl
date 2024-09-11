# README

## Dependencies
- Ruby 3.1.0
- Rails 7.2.1
- Postgres 14.13
- Docker

Use other versions of these dependencies at your own risk.

## Setting up Postgres
Pull the Postgres image
- `docker pull postgres:14.13-alpine`

Run the Postgres container
- `docker run --name postgres_db -e POSTGRES_USER=shorturl -e POSTGRES_PASSWORD=password -d -p 5432:5432 postgres:14.13-alpine`

## Installation
1. Checkout the repository
2. `bundle exec rake db:setup`

## Running the application
`bundle exec rails s`

## Running tests
`bundle exec test`