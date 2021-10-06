# Description

The DnsServerDiagnostics DSC resource manages the debugging and logging
parameters on a Domain Name System (DNS) server.

If the parameter **DnsServer** is set to `'localhost'` then the resource
can normally use the default credentials (SYSTEM) to configure the DNS server
settings. If using any other value for the parameter **DnsServer** make sure
that the credential the resource is run as have the correct permissions
at the target node and the necessary network traffic is permitted.
It is possible to run the resource with specific credentials using the
built-in parameter **PsDscRunAsCredential**.
