## Vcpkg Asset Cache

⚠️ 🚧 Under construction

Cache all vcpkg assets (sources) in a single place to improve build reliability.
Don't let some mirror service interrupt development or CI work.

This tool uses the [Vcpkg asset cache feature](https://learn.microsoft.com/en-us/vcpkg/users/assetcaching) 
(experimental) and attempts to download all assets for a given snapshot of Vcpkg.

Fork the repo, set a few environment variables, and start populating your own 
asset cache today.

## Why do this?

If your project depends on multiple hosts for its source code assets then the 
probability that you can successfully download your assets is the _product_ of 
the hosts' reliability (success probability decreases with each host you add). 
Caching all files in a single, more reliable host can increase your chances of 
a successful build.

Consider 3 hosts:  

| Host | Reliability | Days Downtime per Year | 
| ---- | ----------- | ---------------------- |
| A | 99% | 3.65 | 
| B | 98% | 7.3 | 
| C | 99.9% | 0.365 | 

A project that depends on hosts A, B, and C can expect up to 11.2 days of 
downtime per year. If you could cache all assets on a host that had 99.99% 
uptime then the project can expect 0.0365 days of downtime per year. 

## How to use

I'm currently experimenting with hosting caches in an Azure Storage account that
is publicly accessible. If this becomes too popular I'll look at alternatives.

```bash
export X_VCPKG_ASSET_SOURCES="x-azurl,https://djurekvcpkgcachebuilder.blob.core.windows.net/vcpkg-assets,,read"
```

```pwsh
$env:X_VCPKG_ASSET_SOURCES="x-azurl,https://djurekvcpkgcachebuilder.blob.core.windows.net/vcpkg-assets,,read"
```

Then when you run `vcpkg install` with this environment variable set, vcpkg will
attempt to download source assets from the blob storage account.

## Contribute 

Check out [issues](https://github.com/danieljurek/vcpkg-cache-builder/issues), 
assign yourself and open a Pull Request. Comment if you have questions.

## Support

This tool is provided as-is with no support. This is a personal project and not
a Microsoft-supported tool. There is no warranty or SLA. Use at your own risk.

## License 

See LICENSE
