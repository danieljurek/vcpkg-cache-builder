## Vcpkg Asset Cache

⚠️ 🚧 Under construction. Cache build not complete or reliable.

Cache all vcpkg assets (sources) in a single place to improve build reliability.
Don't let some unreliable mirror service interrupt development or CI work.

![The Vcpkg Asset Cache Robot by DALL-E](logo.png)

_Logo by DALL-E_

This tool uses the [Vcpkg asset cache feature](https://learn.microsoft.com/en-us/vcpkg/concepts/asset-caching) 
(experimental) and attempts to download all assets for a given point in time of
Vcpkg.

Fork the repo and run the tool yourself to populate a cache for your own
projects.

## Why do this?

If your project depends on multiple hosts for its source code assets then the 
probability that you can successfully download your assets is the _product_ of 
the hosts' reliability (success probability decreases with each host you add). 
Caching all files in a single, more reliable host can increase your chances of 
a successful build.

Consider 3 hosts:  

| Host | Reliability | Expected Days Downtime per Year | 
| ---- | ----------- | ------------------------------- |
| A | 99% | 3.65 | 
| B | 98% | 7.3 | 
| C | 99.9% | 0.365 | 

A project that depends on hosts A, B, and C can expect up to 11.2 days of 
downtime per year. If you could cache all assets on a [host that had 99.99% 
uptime](https://www.azure.cn/en-us/support/sla/storage/) then the project can 
expect 0.0365 days of build downtime per year.

## How to use

### Central Hosting

I'm currently experimenting with hosting caches in an Azure Storage account that
is publicly accessible. If it becomes too popular I might need help with 
hosting.

```bash
export X_VCPKG_ASSET_SOURCES="x-azurl,https://djurekvcpkgcachebuilder.blob.core.windows.net/vcpkg-assets,,read"
```

```pwsh
$env:X_VCPKG_ASSET_SOURCES="x-azurl,https://djurekvcpkgcachebuilder.blob.core.windows.net/vcpkg-assets,,read"
```

Then when you run `vcpkg install` with this environment variable set, vcpkg will
attempt to download source assets from the blob storage account.

### Fork and run it yourself

1. Fork the repo 
1. Set up Azure Resources
    1. Create a storage account with a blob container named `vcpkg-assets`
    1. Create an AAD App
        1. [Setup OIDC for GitHub and Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
        1. Assign the `Storage Blob Data Contributor` role to the AAD app in the storage account
1. Set up GitHub Actions in the repo: 
    1. Create an environment named `build-cache` in the environment...
    1. Create secrets using AAD app info: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
    1. Create variable: `STORAGE_ACCOUNT_NAME` with the value of the storage account created in previous steps (e.g. `myvcpkgcache`, leave `blob.core.windows.net` off) 
1. Run the manual `Populate` GitHub Actions Workflow (it'll take a long time)

## Contribute 

Check out [issues](https://github.com/danieljurek/vcpkg-cache-builder/issues), 
assign yourself and open a Pull Request. Issues are vague so comment if any 
questions come up.

## Support

This tool is provided as-is with no support. This is a personal project and not
a Microsoft-supported tool. There is no warranty or SLA. Use at your own risk.

## License 

See LICENSE
