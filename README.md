# capistrano-terraform

Run Terraform tasks as part of your Capistrano v3 deployments; or just plain use Capistrano v3 to run your Terraform, even if you don't deploy your code with Capistrano.

```sh
cap production terraform:deploy # run all registered terraform deployment tasks
```

This plugin also hooks into the default `cap <environment> deploy` flow as a build action. See [Usage](#usage) for more details.

Hence this also works:
```sh
cap production deploy # run all app deployment tasks, and terraform is going to run in there somewhere based on your configs
```


----

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'capistrano', '~> 3.11' # capistrano at least version 3.11
gem 'capistrano-terraform', '~> 1.0' # the meaty bits of this plugin - 1.X to ensure you always have the best available
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install capistrano-terraform
```

----

## Usage

### Configure your project

#### Require in Capfile:
```ruby
require 'capistrano/terraform'
```

#### Optionally define a Terraform host in deploy.rb or the appropriate deploy/stage.rb:
```ruby
role :terraform,  %w{localhost} # role syntax, this one making localhost the terraform agent
# --  or... --
server 'my.build.server', roles: %w{terraform} # server syntax, declaring a remote server
```

If no `:terraform` host/role is defined, all Terraform actions will be ran directly from the host currently running `cap` according to the contents of the current working project directory (some use-cases make this desirable, for example some automated CI/CD pipelines work better this way). A maximum of one `:terraform` host can be defined.

> **Note**: Setting the `:terraform` host/role to `localhost` is *not* the same as leaving it undefined (or set to nil). If the `:terraform` role is defined, the full code checkout process is expected to take place prior to terraform actions.

> _Note: There is currently no embedded mechanism to ensure the declared terraform host/role (or the localhost if none defined) has the necessary permissions to perform the desired terraform actions against the IAAS service provider. It's entirely up to you to preemptively set up any necessary AWS keys, SSH keys, environment variables, etc, to enable the worker to perform the desired terraform actions. For AWS, I've found it easiest to simply set up the aws-cli environment variables/tokens on the host prior to running `cap`. Discussions/proposals around this are welcome as github issues._

#### Optionally define the Terraform root directory:
```ruby
set :terraform_root, "infra"
```
This is the sub-directory from which all `capistrano/terraform` related files/references will be evaluated from. If left undefined, it will be assumed to be the project root directory (ie: where `Capfile` is defined)

#### Declare global Terraform variables, variable files, etc

```ruby
append :terraform_var_file, 'common.tfvars'
```

#### Declare your Terraform project directories and their specific configurations:
The minimum terraform step definition includes a name. The path (relative to `:terraform_root`) is actually optional. For example:
```ruby
terraform :my_terraform_action, path: 'directory/path'
```

If no `:path` option is provided, the `:terraform_root` is the assumed directory.

No checking is performed to ensure that declared terraform project directories are unique by path, only the first parameter for the `terraform` DSL method (ie, the name) is used to determine uniqueness.

All future references to the same terraform action (by name) are additive. This allows you to declare basic Terraform options within the `deploy.rb` config file, and then add/replace options specific to a particular deployment stage within that stage specific `deploy/stagename.rb` config file.

This plugin automatically hooks the normal [Capistrano deploy flow](https://capistranorb.com/documentation/getting-started/flow/) around the _publish_ stage. The default timing is to run terraforms _before_ `deploy:publishing`. However, through a configuration option, terraforms can be selectively performed _after_ `deploy:published` instead.

To select the after publish timing, simply add the `after_publish: true` option setting to individual `terraform` declaration:
```ruby
terraform :my_terraform_action, path: 'directory/path', after_publish: true
```

To opt-out of the deploy flow for all of `capistrano/terraform`, add this line to your `config/deploy.rb` or to a specific `config/deploy/<stage>.rb` file:
```ruby
set :terraform_deploy, false
```

To opt-out of the deploy flow for an individual terraform declaration, simply add `deploy: false` to the declaration options:
```ruby
terraform :my_terraform, path: 'directory/path', deploy: false
```
Individually excluding a terraform from deploys via `deploy: false` also removes it from the `cap <stage> terraform:deploy` flow.

Any terraform actions/project-directories that are excluded from the deploy flow are still available to run individually via `cap terraform:my_terraform:deploy` (or their related tasks).


### Run a deploy:

For a normal full deploy:
```ruby
cap <stage> deploy # the default hooks will run terraform actions at the appropriate times
```

For independent terraform runs:
```ruby
cap <stage> terraform:deploy # runs both the before and after publish tasks, hooks in that order, without attempting to publishing code -- if you're running this within a CI pipeline (like Circle or CodeShip) this is probably what you want for simple terraform-first style projects
```

#### Getting a little more granular...

You should also notice there are a number of granular cap tasks automatically defined around your terraform projects/directories, allowing you to run only what you want, when you want.

> Beware: All granular `cap <stage> terraform:X` tasks will still honor the `:terraform` server role, if one is defined. Something to be aware of...

For example, to selectively run before and after publish deploy stages (without involving the code/app deploy bits):
- `cap <stage> terraform:deploy_before`
- `cap <stage> terraform:deploy_after`

Additionally, every `terraform` declaration within the cap deploy configs generates a number of individually addressable cap tasks that can be ran independently:
- `cap <stage> terraform:<name>:init` # just terraform init
- `cap <stage> terraform:<name>:plan` # just terraform plan
- `cap <stage> terraform:<name>:apply` # just terraform apply
- `cap <stage> terraform:<name>:deploy` # terraform init -> plan -> apply
- ???
- `cap <stage> terraform:<name>:destroy` # just terraform apply
- `cap <stage> terraform:<name>:clean`   # delete any left over plan files and cleans up the .terraform temporary directory


To view all the cap tasks (and their descriptions) that are readily runnable for your project, based on the current config files, run `cap -T` to generate the full list.



### Configurable options:

Global

terraform DSL method










## Why?

Because.

One day I literally put "`capistrano terraform`" into Google and surprisingly didn't find any projects that already directly addressed running Terraform from Capistrano. So here we are.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eshork/capistrano-terraform


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
