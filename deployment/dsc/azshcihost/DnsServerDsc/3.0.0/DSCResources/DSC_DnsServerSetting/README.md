# Description

The DnsServerSetting DSC resource manages the Domain Name System (DNS) server
settings and properties.

If the parameter **DnsServer** is set to `'localhost'` then the resource
can normally use the default credentials (SYSTEM) to configure the DNS server
settings. If using any other value for the parameter **DnsServer** make sure
that the credential the resource is run as have the correct permissions
at the target node and the necessary network traffic is permitted (_WsMan_
protocol). It is possible to run the resource with specific credentials using the
built-in parameter **PsDscRunAsCredential**.

Please see [DnsServerSetting class](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/dnsserverpsprov/dnsserversetting)
for more information around the properties this resource supports.

## Requirements

- Target machine must be running Windows Server 2012 or later.
  - Properties `RootTrustAnchorsURL` and `ZoneWritebackInterval` is not
    supported by _Windows Server 2012_.
  - Properties `IgnoreServerLevelPolicies`, `IgnoreAllPolicies`,
    `ScopeOptionValue`, and `VirtualizationInstanceOptionValue` are not
    supported by _Windows Server 2012_ and _Windows Server 2012 R2_.
