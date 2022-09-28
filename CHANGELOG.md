# 1.1.0 - Multiple fixes & changes

## Enhancements

- Support Singapore DC for `workato push` command. Change `--environment` param to accept a base url instead of hardcoded alias.
  - For example `workato push --environment='live-eu'` becomes `workato push --environment='https://app.eu.workato.com'`
- Improve connection reauthorization logic. Now `detect_on` conditions match only network errors, previously it used to match on any exception.
- Allow array of events for `webhook_notification` output. Previously it expected only a single event. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/sdk-reference/triggers.html#webhook-notification) was updated too.

## Bugfixes

- Fix `to_currency`, `to_phone` methods
- Fix incompatibility of `strip_tags`. Now it sanitises with correct defaults.
- Fix incompatibility of `after_response` callback. Now it correctly detects headers encoding.
- Fix `try` method for request. Now it is called on the response instead of the request object.
- Fix `params` request method for non-hash values. Now method accepts string or array too.

## Misc

- Do not apply `dedup` to `webhook_notification` and `poll` output.
- Raise custom error when call an incorrectly defined method.
- Raise custom error when referring an incorrectly defined object definition.
- Raise custom error when request payload/response format is invalid.
- Raise custom error for request server or client certificate error.

# 1.0.2 - Multiple improvements

## Enhancements

- Use UTC timezone for system timezone and warn if TZ is not UTC
- Implement missing SDK methods: workato.uuid, workato.encrypt, workato.decrypt
- Introduce runtime type checks with Sorbet

## Bugfixes

- Fix default value for webhook_subscribe_output input param

## Misc 

- Update loofah 2.14.0 -> 2.16.0
- Update rubyzip 1.3 -> 2.3
- Update activesupport 5.2.7.1 -> 5.2.8.1
- Refactoring, code polishing, improving stability overall  

# 1.0.1 - Fix String#to_date

## Bugfixes

- Fix String#to_date unexpected argument

# 1.0.0 - Improve webhook_notification, bugfixes

## Enhancements

- Add `settings ` and `webhook_subscribe_output` params to `webhook_notification` callback

## Bugfixes

- Fix `workato exec triggers.test_trigger` incorrectly handles output
- Fix binary string console output

## Misc

- Now `workato exec 'trigger.webhook_unsubscribe'` uses `--webhook-subscribe-output` as input argument. Previously was `--input`

# 0.5.0 - Schema generator

## Enhancements
- Add command `workato generate schema` for easier building schemas from existing sample input/output
- Add `state` param to OAuth2 authorize URL

# 0.4.1 - Fix AWS and update loofah

## Bugfixes
- Fix missing constant in AWS module

## Misc
- Update loofah gem 

# 0.4.0 - AWS, parallel, verify_rsa, decode_url

## Enhancements

- Implement AWS connection methods. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/guides/authentication/aws_auth.html)
- Implement `parallel` method. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/guides/building-actions/multi-threaded-actions.html)
- Implement `verify_rsa` and `decode_url`

## Misc
- Introduce custom `Workato::Connector::SDK::RuntimeError` exception type for `error` method.

# 0.3.0 - Workato Schema, exit codes

## Enhancements

- Add support of Workato Schema. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/sdk-reference/schema.html#attribute-description)
  - Now `input_fields`/`output_fields` is being evaluated and applied to input/output data if action or trigger runs as a whole
- CLI command exits with code `1` on failure

# 0.2.0 - OAuth2 helper, Multistep actions

## Enhancements

- Add command `workato oauth2` for easier OAuth2 Client Credentials flow initial authorization. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/guides/authentication/oauth/auth-code.html#how-to-guide-oauth-2-0-authorization-code-variant)
- Add support of Multistep Actions. [Workato Docs](https://docs.workato.com/developing-connectors/sdk/guides/building-actions/multistep-actions.html#how-to-guides-multistep-actions)

# 0.1.2 - Fixes for Windows, optional folder for push

## Enhancements

- Remove required FOLDER params from `workato push` and push to Home folder by default. `--folder` option is still available for pushing in folder other than Home.

## Bugfixes

- Multiple fixes for Windows platform:
  - fix `worato push` not working
  - handle missing `tzinfo-data` and require it to install
  - fix `workato new` flood terminal with repeated message

# 0.1.1 - Update metadata

## Enhancements

- Update metadata to show correct links on RubyGems.org gem page
- Update `loofah` gem to `2.12.0`

# 0.1.0 - Initial Operations, Settings, CLI, Docs

## Core

- Add support of Custom Connectors DSL, Ruby extensions, and HTTP requests
- Add support of Actions and Triggers
- Add support of Object Definitions
- Add support of Pick Lists

## CLI

- Add generator for a new connector project
- Add generator for rspec for existing connector
- Add ability to push connector code to Workato Platform
- Add ability to edit encrypted files, e.g. settings VCR cassettes, properties etc.

## Documentation

- Added 101 to start connector development
- Added How to run action code from console using CLI
- Added How to write you first action rspec
- Added How to setup CI/CD using GitHub Actions
