# TODO in README.md
- authentication controller for mission_control gem


# Masdiag Mailer

List of tasks to do during deployment on production
1. perhaps Dockerfile7.1 should be used for deploy in production 
2. rails db:prepare    ---- it is needed for solid_queue migration




# LSI validation

As part of the validation of the LSI Masdiag software in accordance with IEC 62304, it is necessary to prepare a software configuration report with each software release.
A script has been created that prepares the data needed to prepare the report.

To run validation script please use the following command:
```bash
rails runner LSI_validation.rb
```










Things you may want to cover:

* Ruby version
* System dependencies
* Configuration
* Database creation
* Database initialization
* How to run the test suite
* Services (job queues, cache servers, search engines, etc.)
* Deployment instructions
* ...

