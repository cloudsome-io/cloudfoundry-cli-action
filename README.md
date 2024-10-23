# CloudFoundry CLI GitHub Action

Runs arbitrary CF CLI commands on GitHub Actions so you can deploy apps, manage infrastructure, and continuously deploy

## Why Use This Action

There are a few key differences between this Action and others (see [cf-cli-action](https://github.com/citizen-of-planet-earth/cf-cli-action.git), [cloud-foundry-cli-action](https://github.com/louisthomas/cloud-foundry-cli-action.git), and [cloudfoundry-action](https://github.com/comsysto/cloudfoundry-action.git))

1. When you specify a tag i.e. `cloudfoundry-cli-action@v6` it will pull the latest release of that major version of the CF CLI. This allows you to be backwards compatible with older CF installations that do not support v7 of the CF CLI
2. When you specify a tag, it will pull down a pre-built Docker image, which should significantly reduce the time your Action takes to execute
3. The images are based on Alpine Linux which has a much smaller footprint

## How to Use this Action

```yml
name: Deploy to CF
on:
    push:
        branches:
            [main]
jobs:
    deploy:
        runs-on: ubuntu-latest
        steps:
        - uses: cloudsome-io/cloudfoundry-cli-action@v7.4.6
          with:
            CF_API: https://api.my-cloud-foundry.com
            USERNAME: ${{ secrets.CF_USER }}
            PASSWORD: ${{ secrets.CF_PASSWORD }}
            ORG: my-org
            SPACE: dev
            COMMAND: cf push <app-name>
```

## blue green deployment
For blue green deployment, you can use the `blue-green.sh` script to deploy your app.  
This script will deploy the app to the staging space and then swap the routes to point to the new app.

```yml
- uses: cloudsome-io/cloudfoundry-cli-action@v7.4.6
  with:
    CF_API: https://api.my-cloud-foundry.com
    USERNAME: ${{ secrets.CF_USER }}
    PASSWORD: ${{ secrets.CF_PASSWORD }}
    COMMAND: blue-green <app-name>
```
