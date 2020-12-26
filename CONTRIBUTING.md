# Rack::Attack: Contributing

Thank you for considering contributing to Rack::Attack.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).

## How can I help?

Any of the following is greatly appreciated:

* Helping users by answering to their [questions](https://github.com/rack/rack-attack/issues?q=is%3Aopen+is%3Aissue+label%3A%22type%3A+question%22)
* Helping users troubleshoot their [error reports](https://github.com/rack/rack-attack/issues?q=is%3Aissue+is%3Aopen+label%3A%22type%3A+error+report%22) to figure out if the error is caused by an actual bug or some misconfiguration
* Giving feedback by commenting in other users [feature requests](https://github.com/rack/rack-attack/issues?q=is%3Aissue+is%3Aopen+label%3A%22type%3A+feature+request%22)
* Reporting an error you are experiencing
* Suggesting a new feature you think it would be useful for many users
* If you want to work on fixing an actual issue and you don't know where to start, those labeled [good first issue](https://github.com/rack/rack-attack/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) may be a good choice

## Style Guide

As an effort to keep the codebase consistent, we encourage the use of [Rubocop](https://github.com/bbatsov/rubocop).
This tool helps us abstract most of the decisions we have to make when coding.

To check your code, simply type `bundle exec rubocop` in the shell. The resulting output are all the offenses currently present in the code.

It is highly recommended that you integrate a linter with your editor.
This way you receive real time feedback about your code. Most editors have some kind of plugin for that.
