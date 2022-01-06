# NPM rule usage guide

In order to publish an NPM package to a repository that requires authorisation (e.g. publishing a release artifact to https://npmjs.com) you need to supply an auth token to the `deploy_npm` rule.

## How to generate an auth token

### On `npmjs.com`
1. Sign in to the user account at https://npmjs.com that is used in your CI and has permissions to publish the package
2. Navigate to the account's "Access Tokens", generate a new one and store it somewhere safe

### On `repo.vaticle.com`, or any other `npm` repository
1. Run `npm adduser <repo_url>` (example: `npm adduser --registry=https://repo.vaticle.com/repository/npm-private`)
2. When prompted, provide login credentials to sign in to the user account that is used in your CI and has permissions to publish the package
3. If successful, a line will be added to your `.npmrc` file (`$HOME/.npmrc` on Unix) which looks like: `//repo.vaticle.com/repository/npm-snapshot/:_authToken=NpmToken.00000000-0000-0000-0000-000000000000`. The token is the value of `_authToken`, in this case `NpmToken.00000000-0000-0000-0000-000000000000`.
4. Save the auth token somewhere safe and then delete it from your `.npmrc` file
