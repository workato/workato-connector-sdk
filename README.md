# `workato-connector-sdk`

# Getting started with the SDK Gem
In this chapter, we'll go over the pre-requisites to get started on using the Workato Gem in a few sections:

This guide below showcases how you can do the following things:
1. [Build, install and run the Workato Gem](#1-build-install-and-run-the-workato-gem)
2. [Setting up your connector project](#2-setting-up-your-connector-project)
3. [Running CLI commands](#3-running-cli-commands) 
4. [Building connectors](#4-building-connectors)
5. [Write and run RSpec tests for your connector](#5-write-and-run-rspec-tests-for-your-connector)
6. [Enable CI/CD on your Github with your connector structure](#6-enabling-cicd-on-github)

## Prerequisites
1. Install [RVM ("Ruby Version Manager")](http://rvm.io/) or a Ruby manager of your choice. You can find more at [here](https://www.ruby-lang.org/en/documentation/installation/)
2. Choose between Ruby versions `2.7.X`, `3.0.X`, `3.1.X`. Our preferred version is `2.7.6`.
3. Verify you're running a valid ruby version. Do this by running either `ruby -v` or the commands within your version manager. i.e., `rvm current` if you have installed RVM.
4. For Windows you need tzinfo-data gem installed as well. `gem install tzinfo-data`
5. SDK depends on `charlock_holmes` gem. Check [gem's documentation](https://github.com/brianmario/charlock_holmes#installing) if you have troubles when install this dependency. Additional [details for Windows](https://github.com/brianmario/charlock_holmes/issues/84#issuecomment-652877605)
   
```bash
ruby -v
Output:
ruby 2.7.X
```

## 1. Install and run the Workato Gem
Installation is also done through bash which then looks for our latest version of the SDK gem in rubygems.org. 

```bash
gem install workato-connector-sdk
```

Verify that your gem is correctly installed by typing in the command `workato` in terminal. You should see the following output:

```bash
Commands:
  workato edit <PATH>            # Edit encrypted file, e.g. settings.yaml.enc
  workato exec <PATH>            # Execute connector defined block
  workato generate <SUBCOMMAND>  # Generates code from template
  workato help [COMMAND]         # Describe available commands or one specific command
  workato new <CONNECTOR_PATH>   # Inits new connector folder
  workato oauth2                 # Implements OAuth Authorization Code flow
  workato push                   # Upload and release connector's code

Options:
  [--verbose], [--no-verbose]  
```

> *Quick Tip*: Typing the `workato` command allows you to know what commands are possible during development. Find out more about individual keys using `workato help edit` etc.

You may also know the exact location of the Workato Gem using `gem which`

```bash
gem which workato-connector-sdk
```
______

## 2. Setting up your connector project
Now that you're familiar with some CLI tools let's get down to actual connector making! We're going to go over some of the basics you'll need that will make your life easier.

Here is a basic summary of how a self-sufficient connector project should look like: (It looks similar to a normal ruby project)
```bash
. # Your connector's root folder
├── .github # Folder which stores information about your Github workflows if you're using github
├── .gitignore # Stores the information which should not be pushed via git
├── Gemfile # Store the dependencies of your project
├── Gemfile.lock # This will be automatically created. 
├── README.md # This will become your Connector's description
├── logo.png # The logo of your connector. Used when you push your connector to Workato.
├── connector.rb # Your actual connector code
├── master.key # Your master key if you're encrypting your files
├── settings.yaml.enc # Where you store your credentials for your connector
├── fixtures # Folder where your input and output JSONs are stored
├── tape_library # Folder where your VCR recordings are stored
├── .rspec
└── spec # Where you store your RSpec tests
    ├── connector_spec.rb
    ├── spec_helper.rb
    └── vcr_cassettes
```

This folder structure isn't something you need to abide by, but we're going to use this structure for the rest of the documentation! 

> *Quick Tip*: You can use the CLI command `workato new <PATH>` which will generated some of the folder above. Some have been omitted to give you freedom to design your connector project as you see fit. 

So let's take a look at what each of the files should contain:

### 2.1 .github
This folder stores information about your github action workflows. This is what we will use later on for running unit tests on Github.

### 2.2 .gitignore
This stores files that should not be pushed via git. Since you have a master.key which is used to encrypt your settings.yaml files and potentially your VCR recordings, this should be added to your .gitignore.
```
/.bundle/
/.yardoc
/_yardoc/
/coverage/
/doc/
/pkg/
/spec/reports/
/tmp/
master.key

# rspec failure tracking
.rspec_status
```

### 2.3 Gemfile
This file declares all the gems (dependencies) that your ruby project will need. All of them are needed for you to run rspec.
```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rspec'
gem 'vcr'
gem 'workato-connector-sdk'
gem 'webmock'
gem 'timecop'
gem 'byebug'
gem 'rubocop' # Only if you want to use rubocop. Not added by default.
```

### 2.4 Gemfile.lock
You don't need to create this file. It'll be created later on. This file just holds a store of all the dependencies you have, their versions, and also the dependencies your dependencies might have.

### 2.5 README.MD
This file shows up on your Github project (or other Git software you use). Use it to document what your connector does! **Not created via `workato new <PATH>` commands.**
When you use the `workato push` command to sync your connector with your Workato workspace, this is the default file for your connector's description.

### 2.6 logo.png
The logo of your connector. **Not created via `workato new <PATH>` commands.**
When you use the `workato push` command to sync your connector with your Workato workspace, this is the default file for your connector's logo.

### 2.7 connector.rb
Well, this is your actual connector code. This file should be a replica of your connector code in Workato.

### 2.8 master.key
The encryption key is used to encrypt your files. This key is not only for encrypting your connection credentials BUT other things that might be sensitive, like account properties. **Not created via `workato new <PATH>` command if you didn't select `secure` for your project settings.**

### 2.9 settings.yaml.enc or setting.yaml
Depending on whether you're encrypting your files or not (you really should!), it'll show as a `.yaml.enc` file or a simple `.yaml` file, respectively. **Not created via `workato new <PATH>` commands.**

Your settings file should have the following structure if you have multiple credentials.
```yaml
[Your connection name]:
  api_key: valid_key
  domain: valid_domain
[Other connections]:
  api_key: invalid_key
  domain: invalid_domain
```

If you only require one set of credentials, you may have the credentials defined at the root level. 
```yaml
api_key: valid_key
domain: valid_domain
```

To create a `settings.yaml.enc` file, you'll need to run the following command - `EDITOR="nano" workato edit settings.yaml.enc` where you can replace `nano` with your preferred editor. You can either add your credentials in then or just save. Both your `settings.yaml.enc` and `master.key` file will be created. Your `master.key` file may have been created if you selected `secure` whilst using `workato new <PATH>`. When you choose to create new encrypted files, the same `master.key` will be used.

IMPORTANT: Be sure to add your `master.key` to your `.gitignore` or similar files if you're committing your project. This key will allow anyone to decrypt your files.

### 2.10 fixtures
The folder where you may store your input and output JSONs for use in RSpec or CLI.
Sample structure:

```bash
├── fixtures
│   ├── actions
│   │   └── search_customers
│   │       ├── input.json
│   │       └── output.json
│   ├── methods
│   │   └── sample_method
│   │       ├── input.json
│   │       └── output.json
│   ├── pick_lists
│   │   └── dependent
│   │       └── input.json
│   └── triggers
│       └── new_updated_object
│           ├── customer_config.json
│           ├── customer_input_poll.json
│           ├── customer_input_poll_page.json
│           ├── customer_output_fields.json
│           ├── customer_output_poll.json
│           └── customer_output_poll_page.json
```

### 2.11 .rspec
Holds standard options which will be passed to RSpec whenever it is run.

Sample .rspec contents:
```
--format documentation
--color
--require spec_helper
```

### 2.12 tape_libarary
Where RSpec will store your VCR cassettes of API requests recorded. These requests are essential for stable unit tests. **Not created via `workato new <PATH>` commands BUT created when RSpec is run.**

### 2.13 Your spec folder
This is the folder that will contain all your RSpec tests. RSpec is a ruby testing tool that can be used in conjunction with our Workato Gem to allow you to define, write and run unit tests for your connector!

#### 2.13.1 connector_spec.rb
This is your connector's main rspec file which holds all unit tests for your connector. You could split up your connector spec file into multiple folders if it helps organize your spec tests. All of your spec tests can be run in a single command using `bundle exec rspec`.

#### 2.13.2 spec_helper.rb
This file contains all the commands that should be setup before each rspec run. You may copy the files directly below. [See section 5 for more details of what the `spec_heper.rb` file should look like.](#5-write-and-run-rspec-tests-for-your-connector)

__________

## 3. Running CLI commands
So you've set up your project, and you're finally ready to get started on improving your connector. 

### 3.1 workato help 
```bash
workato help

Commands:
  workato edit <PATH>            # Edit encrypted file, e.g. settings.yaml.enc
  workato exec <PATH>            # Execute connector defined block
  workato generate <SUBCOMMAND>  # Generates code from template
  workato help [COMMAND]         # Describe available commands or one specific command
  workato new <CONNECTOR_PATH>   # Inits new connector folder
  workato oauth2                 # Implements OAuth Authorization Code flow
  workato push                   # Upload and release connector's code

Options:
  [--verbose], [--no-verbose]  
```

You may also gain more info about a specific command via `workato help [command]`

```
workato help [command]

[ Help for specific Workato gem command ]
```

### 3.2 workato edit
```
workato help edit

Usage:
  workato edit <PATH>

Options:
  -k, [--key=KEY]                  # Path to file with encrypt/decrypt key.
                                   # NOTE: key from WORKATO_CONNECTOR_MASTER_KEY has higher priority
      [--verbose], [--no-verbose]

Edit encrypted file, e.g. settings.yaml.enc
```

> *NOTE*: You will need to use this method to create any encrypted file. When you run this command for the first time, the `.enc` file will be created and the `master.key` will be created. 

> *NOTE*: If no key is specified in your command, the gem will look for the key `master.key` in the root folder of whichever directory you're calling the command from.

### 3.3 workato exec
```
workato help exec

Usage:
  workato exec <PATH>

Options:
  -c, [--connector=CONNECTOR]                                # Path to connector source code
  -s, [--settings=SETTINGS]                                  # Path to plain or encrypted file with connection configs, passwords, tokens, secrets etc
  -n, [--connection=CONNECTION]                              # Connection name if settings file contains multiple settings
  -k, [--key=KEY]                                            # Path to file with encrypt/decrypt key.
                                                             # NOTE: key from WORKATO_CONNECTOR_MASTER_KEY has higher priority
  -i, [--input=INPUT]                                        # Path to file with input JSON
      [--closure=CLOSURE]                                    # Path to file with next poll closure JSON
      [--continue=CONTINUE]                                  # Path to file with next multistep action continue closure JSON
  -a, [--args=ARGS]                                          # Path to file with method arguments JSON
      [--extended-input-schema=EXTENDED_INPUT_SCHEMA]        # Path to file with extended input schema definition JSON
      [--extended-output-schema=EXTENDED_OUTPUT_SCHEMA]      # Path to file with extended output schema definition JSON
      [--config-fields=CONFIG_FIELDS]                        # Path to file with config fields JSON
  -w, [--webhook-payload=WEBHOOK_PAYLOAD]                    # Path to file with webhook payload JSON
      [--webhook-params=WEBHOOK_PARAMS]                      # Path to file with webhook params JSON
      [--webhook-headers=WEBHOOK_HEADERS]                    # Path to file with webhook headers JSON
      [--webhook-subscribe-output=WEBHOOK_SUBSCRIBE_OUTPUT]  # Path to file with webhook subscribe output JSON
      [--webhook-url=WEBHOOK_URL]                            # Webhook URL for automatic webhook subscription
  -o, [--output=OUTPUT]                                      # Write output to JSON file
      [--oauth2-code=OAUTH2_CODE]                            # OAuth2 code exchange to tokens pair
      [--redirect-url=REDIRECT_URL]                          # OAuth2 callback url
      [--refresh-token=REFRESH_TOKEN]                        # OAuth2 refresh token
      [--debug], [--no-debug]
      [--verbose], [--no-verbose]

Description:
  The 'workato exec' executes connector's lambda block at <PATH>. Lambda's parameters can be provided if needed, see options part.

  Example:

  workato exec actions.foo.execute # This executes execute block of foo action

  workato exec triggers.bar.poll # This executes poll block of bar action

  workato exec methods.bazz --args=input.json # This executes methods with params from input.json
```

There are a few assumptions we make when you don't declare arguments:
1. `--connector` is assumed to be `connector.rb`
2. `--settings` is assumed to be `settings.yaml.enc` or `settings.yaml` as a fallback
3. `--connection` is NOT assumed. But if there is only one set of credentials in the file, we will use that.

Some other things of note:
1. `--verbose` allows you to track all incoming and outgoing API requests.
2. `--input` allows you to reference a file which is the json input to your execute block
3. `--output` allows you to write or overwrite the output of a specific CLI utility.

### 3.4 workato generate
```
workato help generate

Commands:
  workato generate help [COMMAND]  # Describe subcommands or one specific subcommand
  workato generate schema          # Generate schema by JSON example
  workato generate test            # Generate empty test for connector
```

### 3.4.1 workato generate schema
Use command to generate Workato Schema from a sample file. Supported inputs csv, json

```
workato generate help schema

Usage:
  workato generate schema

Options:
  [--json=JSON]            # Path to JSON sample file
  [--csv=CSV]              # Path to CSV sample file
  [--col-sep=COL_SEP]      # Use separator for CSV converter
                           # Default: comma
                           # Possible values: comma, space, tab, colon, semicolon, pipe
  [--api-token=API_TOKEN]  # Token for accessing Workato API or set WORKATO_API_TOKEN environment variable
```

### 3.4.2 workato generate test

- Use `workato generate test` to generate tests based on your connector.rb file.

### 3.5 workato new
```
workato help new

Usage:
  workato new <CONNECTOR_PATH>

Options:
  [--verbose], [--no-verbose]

Description:
  The 'workato new' command creates a new Workato connector with a default directory structure and configuration at the path you specify.

  Example: workato new ~/dev/workato/random

  This generates a skeletal custom connector in ~/dev/workato/random.
```

This helps you to create a sample connector project. You may also use `workato new ./[Connector_name]` to create it in the current directory you're in. There may be secondary questions which prompt you about HTTP mocking behaviour.

```
      create  
      create  Gemfile
      create  connector.rb
      create  .rspec
Please select default HTTP mocking behavior suitable for your project?

1 - secure. Cause an error to be raised for any unknown requests, all request recordings are encrypted.
            To record a new cassette you need set VCR_RECORD_MODE environment variable

            Example: VCR_RECORD_MODE=once bundle exec rspec spec/actions/test_action_spec.rb

2 - simple. Record new interaction if it is a new request, requests are stored as plain text and expose secret tokens.

```

- `secure` means all your unit test's HTTP requests will be encrypted. HTTP requests are recorded via [VCR](https://github.com/vcr/vcr) to ensure your tests are stable. As such, we also provide you an easy way to encrypt these recordings so your authorization credentials are not stored in plain text. **This is recommended.**

- `simple` means your HTTP requests will be stored in plain text.

### 3.6 workato oauth2
```
workato help oauth2

Usage:
  workato oauth2

Options:
  -c, [--connector=CONNECTOR]      # Path to connector source code
  -s, [--settings=SETTINGS]        # Path to plain or encrypted file with connection configs, passwords, tokens, secrets etc
  -n, [--connection=CONNECTION]    # Connection name if settings file contains multiple settings
  -k, [--key=KEY]                  # Path to file with encrypt/decrypt key.
                                   # NOTE: key from WORKATO_CONNECTOR_MASTER_KEY has higher priority
      [--port=PORT]                # Listen requests on specific port
                                   # Default: 45555
      [--ip=IP]                    # Listen requests on specific interface
                                   # Default: 127.0.0.1
      [--https], [--no-https]      # Start HTTPS server using self-signed certificate
      [--verbose], [--no-verbose]

Implements OAuth Authorization Code flow
```

Use this to implement the OAuth2 Authorization code grant flow for applicable connectors. Applicable connectors are ones where the connection hash has `type: 'oauth2`. For more information, check out our guide on our [main docs site](https://docs.workato.com/developing-connectors/sdk/guides/authentication/oauth/auth-code.html#how-to-guide-oauth-2-0-authorization-code-variant).

### 3.7 workato push
```
workato help push

Usage:
  workato push

Options:
  -t, [--title=TITLE]              # Connector title on the Workato Platform
  -d, [--description=DESCRIPTION]  # Path to connector description: Markdown or plain text
  -l, [--logo=LOGO]                # Path to connector logo: png or jpeg file
  -n, [--notes=NOTES]              # Release notes
  -c, [--connector=CONNECTOR]      # Path to connector source code
      [--api-token=API_TOKEN]      # Token for accessing Workato API.
                                   # If present overrides value from WORKATO_API_TOKEN environment variable.
      [--environment=ENVIRONMENT]  # Data center specific URL to push connector code.
                                   # If present overrides value from WORKATO_BASE_URL environment variable.
                                   # Examples: 'https://app.workato.com', 'https://app.eu.workato.com'
      [--folder=FOLDER]            # Folder ID if you what to push to folder other than Home
      [--verbose], [--no-verbose]

Upload and release connector's code
```

This allows you to push your connector code from your connector project locally to your workspace. This allows you to quickly cycle from testing connector functionality and the UX of your connector.

______

## 4. Building connectors
At this point, we should highlight some of the key differences between building your connector on Workato's Cloud SDK console and using the Workato Gem.

| Workato Cloud SDK Console | Workato Gem |
|-|-|
| Able to test connections, actions and triggers in their entirety | Able to test specific keys of a connector separately. i.e. execute: and output_fields: can be tested separately |
| Able to debug the exact look and feel of input and output fields. i.e. dynamic input and output fields | No UI but able to quickly evaluate resultant Workato schema of input and output fields using CLI Utils |
| No unit tests available | Able to convert CLI commands into unit tests quickly |
| No access to account_properties or lookup tables in debugger console | Able to store account_properties and credentials in encrypted/unencrypted formats. Able to store lookup tables in unencrypted format. |                                                         |

As we continue to improve on the Workato Gem and its capabilities, more features will soon be added to the Workato Gem. In the meantime, here is an example how the Cloud console and the gem can be used in conjunction with each other.

### 4.1 Starting a connector build
1. Upon creating a new connector on Workato, you will need to first establish connectivity on the cloud console. This is essential for you to do before you bring your connector development locally using the Workato Gem.
2. After you have completed successfully creating a connection, you should have a few things on hand 
    - A set of working credentials
    - Your connector code with a working set of credentials
3. Now, you're able to start creating your project structure (defined in step 2 of this guide) with this connector code.
4. Enter in your working credentials in the format detailed in [step 2.8](#_2-8-settings-yaml-enc-or-setting-yaml)
5. Now you're ready to begin development using the SDK gem.

### 4.2 Example: Testing your connection on CLI - All auths except OAuth 2 - auth code grant flows
Assuming we have a simple connector that uses API key authentication like this:
```ruby
{
  title: "Chargebee",

  connection: {
    fields: [ 
      {
        name: "api_key",
        control_type: "password",
        hint: "You can find your API key " \
          "under 'Settings'=>'Configure Chargebee'=>'API Keys and Webhooks'" \
          " in Chargebee's web console.",
        label: "Your API Key"
      },
      {
        name: "domain",
        control_type: "subdomain",
        url: "chargebee.com"
      }
    ],

    authorization: {
      type: "basic_auth",

      apply: lambda do |connection|
        user(connection['api_key'])
      end
    },

    base_uri: lambda do |connect|
      "https://#{connect['domain']}.chargebee.com"
    end
  },

  test: lambda do |connection|
    get("/api/v2/plans")
  end,

  # More code below
}
```

and a `settings.yaml.enc` or `settings.yaml` file with the following details

```yaml
My Valid Connection:
  api_key: valid_api_key
  domain: valid_domain
My Invalid Connection:
  api_key: invalid_api_key
  domain: invalid_domain
```

You can now run the following commands to verify that the `test:` lambda function you have defined is working:
```bash
workato exec test  --connection='My Valid Connection' #Output of the test: lambda function should be shown
workato exec test  --connection='My Invalid Connection' #You should see a `Workato::Connector::Sdk:RequestError` highlighting 401 unauthorized
```

You needn't have to declare the settings file. The Workato Gem automatically looks for a `settings.yaml.enc` or `settings.yaml` file (by this exact file name) so you don't need to declare it.

> *Note*: The output of this lambda function often isn't important. As with the behaviour of the `test:` in the cloud console, Workato only requires that this lambda function (and all HTTP requests within) are invoked successfully. 

Alternatively, you may also have your `settings.yaml` or `settings.yaml.enc` file with the structure below

```yaml
api_key: valid_api_key
domain: valid_domain
```

You can now run the following commands to verify that the `test:` lambda function you have defined is working:

```bash
workato exec test #Output of the test: lambda function should be shown
```

> *Note*: This, of course, removes one less declaration in your call. You may also choose to store your invalid credentials in another file like `invalid_settings.yaml.enc`

> *Note*: You may also see a intermediary command from the Gem asking if you'd like to refresh your access tokens. This is done when HTTP requests are made which have a response that triggers the `refresh_on` block. Selecting yes would cause the Gem to update your settings file with the latest auth credentials.

### 4.3 Example: Testing your connection on CLI - OAuth 2 - auth code grant flows
For auth code grant flows, the Workato Gem allows you to simulate the OAuth2 flow using the `workato oauth2` command.

```ruby
{
    title: 'TrackVia',
    connection: {
      fields: [
        {
          name: 'custom_domain',
          control_type: 'subdomain',
          label: 'TrackVia subdomain',
          hint: 'Enter your TrackVia subdomain. e.g. customdomain.trackvia.com. By default, <b>go.trackvia.com</b> will be used.',
          optional: 'true'
        },
        {
          name: 'client_id'
        },
        {
          name: 'client_secret',
          control_type: 'password'
        }
      ],

      authorization: {
        type: 'oauth2',

        authorization_url: lambda do |connection|
          "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}/oauth/authorize?response_type=code"
        end,

        acquire: lambda do |connection, auth_code, redirect_uri|
          url = "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}"
          response = post("#{url}/oauth/token").payload(
            redirect_uri: redirect_uri,
            grant_type: 'authorization_code',
            code: auth_code,
            client_id: connection['client_id'],
            client_secret: connection['client_secret']
          ).request_format_www_form_urlencoded
          user_key = get("#{url}/3scale/openapiapps").params(access_token: response['access_token']).dig(0, 'userKey')
          [
            response,
            nil,
            {
              user_key: user_key
            }
          ]
        end,

        refresh: lambda do |connection, refresh_token|
          url = "https://#{connection['custom_domain'].presence || 'go.trackvia.com'}"
          post("#{url}/oauth/token").payload(
            client_id: connection['client_id'],
            client_secret: connection['client_secret'],
            grant_type: 'refresh_token',
            refresh_token: refresh_token
          ).request_format_www_form_urlencoded
        end,

        refresh_on: [401, 403],

        apply: lambda { |connection, access_token|
          params(user_key: connection['user_key'])
          headers(Authorization: "Bearer #{access_token}")
        }
      },

      base_uri: lambda do |connection|
        if connection['custom_domain'].presence
          "https://#{connection['custom_domain']}/openapi/"
        else
          "https://go.trackvia.com/openapi/"
        end
      end
    },

    test: ->(_connection) { get('views') },
  # More code below
}
```

and a `settings.yaml.enc` or `settings.yaml` file with the following details

```yaml
client_id: valid_client_id
client_secret: valid_client_secret
```

You can now run the following commands to go through the OAuth2 Authorization code flow which includes a browser popup.
```bash
workato oauth2 
```

https://user-images.githubusercontent.com/25265275/137942408-812fa6ad-353f-4ea2-bf37-f804e2ff7b04.mov


> *Note*: `--verbose` can be used to detail everything, including the HTTP requests.


Now after you've successfully gone through the flow, you may be use the same `workato exec test` command to verify you're applying your token properly in your requests! Depending on when you received your token, you may also see a intermediary command from the Gem asking if you'd like to refresh your access tokens (if it has expired). This is done when HTTP requests are made which have a response that triggers the `refresh_on` block. Selecting "Yes" would cause the Gem to update your settings file with the latest auth credentials.

Take note, you may also use `workato exec` to execute lambdas in your `authorization` hash like `acquire` and `refresh`. **That said, we highlight recommend you use `workato exec test` and `workato oauth2` which handle the updating of your `settings.yaml` file automatically.**

### Example: Testing a sample action on CLI
Continuing from the previous example, let's take a look at a simple action and invoke the individual lambda functions.
```ruby
{
  title: "Chargebee",

  connection: {
      # Connection code found above
  },

  test: lambda do |connection|
    get("/api/v2/plans")
  end,

  actions: {
    
    search_customers: {
      title: "Search customers",
      subtitle: "Search for customers using name",
      description: "Search customer in Chargebee",
      
      input_fields: lambda do |object_definitions|
        [ 
          {
            name: "name",
            label: "Name to query by",
            hint: "Provide the name of the customer to query"
          },
          {
            name: "id",
            label: "Name to query by",
            hint: "Provide the name of the customer to query"
          }
        ]
      end,
      
      
      execute: lambda do |connection, input, input_schema, output_schema, closure|
        get("/api/v2/customers",input)
      end,
      
      
      output_fields: lambda do |object_definitions|
        [
          {
            name: "first_name"
          },
          {
            name: "last_name"
          },
          {
            name: "id"
          }
        ]
      end
    }
    
  },
}
```

And a `settings.yaml.enc` or `settings.yaml` that is the same as the example for testing your connection.

You can now run the following commands to execute the `execute:` lambda function for this action.
```bash
workato exec actions.search_customers.execute --connection="My Valid Connection" --input="fixtures/actions/search_customer/search_customer_input.json"  #The output of the lambda function should be shown.
```
Let's decompose this command.

- `workato exec actions.search_customers.execute` defines that you first want to test an action, followed by `search_customers` which is the key for the action you're testing. `execute` tells us that you want to test the `execute:` lambda function. 

- `--connection="My Valid Connection"` tells us to use the connection named "My Valid Connection" in our settings file. If your settings file only has one set of connection settings, you don't need to define this.

- `--input="fixtures/actions/search_customer/search_customer_input.json"` The path to the input json file which mimics the `input` argument for the `execute:` lambda function.

Now, this command assumes a few things which you can also specify.

- The file in which the credentials are stored (assumed to be `settings.yaml` or `settings.yaml.enc`) but you can specify it with `--settings=`. If the `connection` argument is used in the `execute` lambda function, this is used for that. It is also used for any authorization logic required for your action's HTTP requests.

- The connector to reference for the path (`actions.search_customers.execute`). Assumed to be `connector.rb` but you can specify it with `--connector=`

> *NOTE*: Use `workato help exec` to find more arguments you can use!

### Example: Testing a method in the CLI
So let's talk about testing a method as well. Methods in connectors are essential to reuse code for data pre or post-processing or to store Workato schema.

```ruby
{
  title: "Chargebee",

  connection: {
      # Connection code found above
  },

  test: lambda do |connection|
    get("/api/v2/plans")
  end,

  methods: {
    
    sample_method: lambda do |string1, string2|
      string1 + string2
    end
  },
}
```

You can now run the following commands to execute the lambda function for this method.
```bash
workato exec methods.sample_method --args='fixtures/methods/sample_method/sample_method_input.json'  #The output of the lambda function should be shown.
```
Let's decompose this command.

- `workato exec methods.sample_method` defines that you first want to test a method, followed by `sample_method`, which is the key for the method you're testing.  
- `--args='fixtures/methods/sample_method/sample_method_input.json'` tells us to execute the method with the arguments found in the "sample_method_input.json".

The `sample_method_input.json` might look like this:

```json
[
    "hello",
    "world"
]
```

As you can see, the json is an array where each index belongs to each argument in the method (`string1` and `string2`), respectively. If only one argument is needed, you could give a single index array or provide the value itself!

> *Quick Tip*: Testing methods which need to send HTTP requests
> Since some methods also send outgoing HTTP requests, you may supply `--settings` to supply authorization credentials. If not, the method will default to your `settings.yaml.enc` or `settings.yaml` file.

### Example: Using byebug with your connector
You may also use byebug in conjunction with your CLI tools to debug efficiently. Do this by first adding `require 'byebug'` to the top of your connector file. Then you may place the word `byebug` anywhere in your code to set a breakpoint for additional debugging. 


```ruby
require 'byebug' # added before your connector

{
  title: "Chargebee",
  # More code here
  methods: {
    get_customers: lambda do
      response = get('/api/v2/customers')
      byebug
      response
    end,

    sample_method: lambda do |string1, string2|
      byebug
      string1 + ' ' + string2
    end
  }
}
```

where running the sample_method on CLI would allow you to print out variables and control the execution flow of the connector.
```bash
workato exec methods.sample_method --args='input/sample_method_input.json' 

[777, 786] in connector.rb
   777:       byebug
   778:       response
   779:     end,
   780: 
   781:     sample_method: lambda do |string1, string2|
   782:       byebug
=> 783:       string1 + ' ' + string2
   784:     end
   785:   }
   786: }
(byebug) string1
"hello"
(byebug) string2
"world"
(byebug) c
```

> `c` in byebug means continue, which allows the execution to continue forward. Read more on how to use byebug [here.](https://www.sitepoint.com/the-ins-and-outs-of-debugging-ruby-with-byebug/)

______

## 5. Write and run RSpec tests for your connector
So now that you can run CLI commands let's get to the fun stuff! Writing unit tests to prevent regressions with your connector. 

Let's begin by revisiting that folder structure we saw in step 2.

```bash
.
├── Gemfile
├── Gemfile.lock
├── README.md
├── connector.rb
├── fixtures # Folder to store all your input and output jsons for CLI commands and tests
│   ├── actions
│   │   └── search_customers
│   │       ├── search_customers_input.json
│   │       └── search_customers_output.json
│   └── methods
│       ├── get_all_output_fields
│       │   └── args.json
│       └── make_schema_builder_fields_sticky
│           ├── make_schema_builder_fields_sticky_input.json
│           └── make_schema_builder_fields_sticky_output.json
├── invalid_settings.yaml.enc
├── master.key
├── settings.yaml.enc
├── .rspec
└── spec
    ├── connector_spec.rb
    └── spec_helper.rb
```

You may see that a few more files have been added. 

1. `fixtures`
These folders here are for you to store your input and output jsons for various parts of your connector you want to test. Keep in mind that you'll use input json files to test your connector's actions, triggers, methods etc. Input jsons should be formed manually (You may be able to design them yourself or also use the debugger console on the cloud SDK to build these jsons). Output jsons can be created from CLI commands by declaring the `--output` parameter to save the output of a CLI command to a file.

2. `.rspec` file
Holds the configurations for your RSpec runs. The `.rspec` file specifies default flags that get passed to the rspec command when you run your tests. So if you want one of the options you see listed on `rspec --help` to apply by default, you can add them here. `--format documentation` allows your tests to be grouped. `--color` enables coloring in the rspec output. `--require spec_helper` tells your rspec runs to require your `spec_helper.rb` before every run.

```
--format documentation
--color
--require spec_helper
```

3. spec folder
Your spec folder will contain various files and folders that will allow you to run rspec - a ruby unit testing framework. Most of your tests will be contained inside the `connector_spec.rb` file but we'll go over the other files in the folder first.

- `spec_helper.rb` - loaded in every rspec run where you can define certain common attributes. You can learn more about what configurations you can give over [here.](https://github.com/rspec/rspec-core) 
```ruby
# frozen_string_literal: true

require "webmock/rspec"
require "timecop"
require "vcr"
require "workato-connector-sdk"
require "workato/testing/vcr_encrypted_cassette_serializer"
require "workato/testing/vcr_multipart_body_matcher"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "tape_library"
  config.hook_into :webmock
  config.cassette_serializers[:encrypted] = Workato::Testing::VCREncryptedCassetteSerializer.new
  config.register_request_matcher :headers_without_user_agent do |request1, request2|
    request1.headers.except("User-Agent") == request2.headers.except("User-Agent")
  end
  config.register_request_matcher :multipart_body do |request1, request2|
    Workato::Testing::VCRMultipartBodyMatcher.call(request1, request2)
  end
  config.default_cassette_options = {
    record: ENV.fetch('VCR_RECORD_MODE', :none).to_sym,
    serialize_with: :encrypted,
    match_requests_on: %i[uri headers_without_user_agent body]
  }
  config.configure_rspec_metadata!
end
```

> *Quick Tip*: This spec_helper.rb is generated for you when you use `workato new <PATH>` to generate a new connector. The example above shows a spec_helper.rb which is created when your project is `secure`. This encrypts all VCR recordings using your `master.key`. **By default our record mode for secure is `none` which means no new VCR cassettes are recorded. You can change this by setting a new environment variable `VCR_RECORD_MODE` to `once`.**

- `vcr_cassettes` - VCR allows us to record API requests and stub the response after it is recorded. Find out more [here.](https://relishapp.com/vcr/vcr/docs)

4. Your connector_spec file (also contained in your spec folder)

Here's how your connector_spec file MAY look like. Of course, you're able to configure your spec file to your team's liking. 
We won't go into too much detail about how to write RSpec because it's ultimately up to you how you want to build your unit tests! Below we have a sample that you might find helpful. I also like this [tutorial here.](https://semaphoreci.com/community/tutorials/getting-started-with-rspec). Below, you can see an example

```ruby
# frozen_string_literal: true

RSpec.describe 'connector', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb', settings) }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }

  it { expect(connector).to be_present }

  describe 'test' do
    subject(:output) { connector.test(settings) }

    context 'given valid credentials' do
      it 'establishes valid connection' do
        expect(output).to be_truthy
      end

      it 'returns response that is not excessively large' do
        # large Test responses might also cause connections to be evaluated wrongly
        expect(output.to_s.length).to be < 5000
      end
    end

    context 'given invalid credentials' do
      let(:settings) { Workato::Connector::Sdk::Settings.from_encrypted_file('invalid_settings.yaml.enc'}

      it 'establishes invalid connection' do
        expect { output }
          .to raise_error('500 Internal Server Error')
      end
    end
  end
end
```

> *Quick Tip*: You may also use the command `workato generate test` to generate RSpec test stubs for you to begin writing unit tests for your connector. This handles most of the heavy lifting such as instantiating your connector or settings.

### 5.1 Running RSpec
To run RSpec, you should have the project structure setup. Running rspec is as easy as running the Workato Gem in CLI. You simply type `bundle exec rspec` in bash in your project home directory, and rspec should begin running. 

> note: you may also run `rspec` but using `bundle exec rspec` ensures that the rspec Gem version you're using to run the tests is the version specified in your Gemfile.

You may also use run only specific tests at a time. If not, rspec will run all spec files in your spec folder.

```bash
bundle exec rspec ./spec/connector_spec.rb:16 #Runs the test or group of tests at line 16 of your spec file. 
```

### 5.2 Using the Workato Gem in your connector_spec.rb
First, your spec file should have included at least `require 'bundler/setup'` and `require 'workato-connector-sdk'`. Include `require 'json'` to read JSON files as well!

#### 5.2.1 Instantiating your connector
To instantiate your connector, you can use this:
```ruby
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb', settings) }
```

#### 5.2.2 Instantiating your settings
To instantiate your settings, you can use `from_default_file` which defers to your `settings.yaml.enc` or `settings.yaml` file.
```ruby
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }
```

To instantiate your settings from an alternative setting file, you can use `from_encrypted_file` or `from_file`.
```ruby
  let(:settings) { Workato::Connector::Sdk::Settings.from_encrypted_file('invalid_settings.yaml.enc') }
```

#### 5.2.3 Testing your test: key
```ruby
subject(:output) { connector.test(settings) } # executes the test: key when the subject `output` is used.
```

This method accepts 1 argument. `settings` in the first position similar to the `test:` lambda.

Example:
```ruby
    context 'given valid credentials' do
      it 'establishes valid connection' do
        expect(output).to be_truthy # Since the test lambda gives a response, it is truthy.
      end

      it 'returns response that is not excessively large' do
        # large Test responses might also cause connections to be evaluated wrongly
        expect(output.to_s.length).to be < 5000
      end
    end
```

#### 5.2.4 Testing an action
```ruby
  let(:action) { connector.actions.copy_asset }
```

This method accepts four arguments. `settings` in the first position. `input` in the second position. `extended_input_schema` and `extended_output_schema` in the third and fourth position, respectively. In our example below, we have omitted `extended_input_schema` and `extended_output_schema` as they were not used in the action.

Example:
```ruby
  describe 'execute' do
    subject(:output) { action.execute(settings, input) }

    context 'given asset'
      let(:input) { JSON.parse(File.read('fixtures/actions/copy_asset/copy_asset_input.json')) }
      let(:expected_output) { JSON.parse(File.read('fixtures/actions/copy_asset/copy_asset_output.json')) }
      it 'uploads asset'
        expect(output).to eq(expected_output)
      end
    end
  end
```

#### 5.2.4 Testing a method
```ruby
connector.methods.[method_name](*input) # Where the arguments depend on your method definition. 
```

There are two ways to define your method in your tests. You can pass the arguments directly or from a file. For example, given a method:
```ruby
 sample_method: lambda do |string1, string2|
   string1 + ' ' + string2
 end
```

In RSpec, you may pass the `string1` and `string2` arguments directly.
```ruby
  connector.methods.sample_method("hello", "world")
```

Or use the same JSON file `sample_method_input.json` we had in [step 4.3](#example-testing-a-method-in-the-cli)

```ruby
 input = JSON.parse(File.read('input/sample_method_input.json'))
 output = connector.methods.sample_method(*input)
```

Here's another example, given a method:
```ruby
make_schema_builder_fields_sticky: lambda do |input|
  input.map do |field|
    if field[:properties].present?
      field[:properties] = call("make_schema_builder_fields_sticky",
                                field[:properties])
    elsif field["properties"].present?
      field["properties"] = call("make_schema_builder_fields_sticky",
                                 field["properties"])
    end
    field[:sticky] = true
    field
  end
end,
```

In RSpec, your tests for it may look something like this:
```ruby
RSpec.describe 'methods/make_schema_builder_fields_sticky', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb') }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }

  subject(:result) { connector.methods.make_schema_builder_fields_sticky(arg_1) }

  context 'given non-sticky schema' do
    let(:arg_1) { JSON.parse(File.read('fixtures/methods/make_schema_builder_fields_sticky/make_schema_builder_fields_sticky_input.json')) }
    let(:expected_output) { JSON.parse(File.read('fixtures/methods/make_schema_builder_fields_sticky/make_schema_builder_fields_sticky_output.json')) }
    it 'makes all fields sticky' do 
      expect(result).to eq(expected_output)
    end
  end
end
```

> For methods that send HTTP requests, the credentials used are the ones you instantiate your connector with. i.e. `Workato::Connector::Sdk::Connector.from_file('connector.rb', settings)`

## 6. Enabling CI/CD on Github
This process should remain similar to other CI/CD tools. First, you want to set up dependencies in your CI/CD environment. Depending on whether you're reading this during the Workato Gem's Beta phase or not, you might need to include the Workato Gem's original gemspec and dependencies to build the Workato Gem. When the gem is publicly available, we will release the Workato Gem to rubygems.org, so bundle install should suffice.

Afterward, you will need to create a GitHub workflows file. Under the `.github/workflows` folder, create a `ruby.yml` file. 

> Note: If you are using encrypted settings (`settings.yaml.enc`), be sure to add your master.key to your `.gitignore` and set your environment variables in your Github repository. Find out more [here.](https://docs.github.com/en/actions/reference/encrypted-secrets) Your variable should be your master.key's contents. We named it `WORKATO_CONNECTOR_MASTER_KEY` for the purpose of the example below. This environment variable will be used to run the rspec instead of your `master.key` file which shouldn't be present in your Github repository.


```yaml
name: Connector Unit Test

on: 
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:

    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby-version: ['2.7', '3.0', '3.1']

    steps:
    - uses: actions/checkout@v2
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ matrix.ruby-version }}
        bundler-cache: true 
    - name: Run tests
      env: # Only needed if using encrypted files.
        WORKATO_CONNECTOR_MASTER_KEY: ${{ secrets.WORKATO_CONNECTOR_MASTER_KEY }} 
      run: bundle exec rspec
    # - name: Push to DEV workspace # Use this to push to DEV. This can be enabled when a PR is merged.
    #   env: 
    #     WORKATO_API_TOKEN: ${{ secrets.WORKATO_DEV_ENVIRONMENT_API_TOKEN}} 
    #   run: workato push
```

You may also add more Github actions for rubocop to automate this.