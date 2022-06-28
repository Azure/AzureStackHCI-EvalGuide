# Localized resources for en-US.

ConvertFrom-StringData @'
    GetServerAuthorizationMessage = Get the current state of the server authorization for the server '{0}'.
    SetServerAuthorizationMessage = Changing the server authorization for the server '{0}' to the desired state.
    TestServerAuthorizationMessage = Evaluating the server authorization for the server '{0}' if it is in the desired state.
    ResolvingIPv4Address = Resolving first local IPv4 IP address.
    ResolvingHostname = Resolving local hostname.
    AuthorizingServer = Authorizing DHCP Server '{0}' with IP address '{1}'.
    UnauthorizingServer = Unauthorizing DHCP Server '{0}' with IP address '{1}'.
    ServerIsAuthorized = DHCP Server '{0}' with IP address '{1}' IS authorized.
    ServerNotAuthorized = DHCP Server '{0}' with IP address '{1}' is NOT authorized.
    IncorrectPropertyValue = Property '{0}' is incorrect. Expected '{1}', actual '{2}'.
    ResourceInDesiredState = DHCP Server '{0}' is in the desired state.
    ResourceNotInDesiredState = DHCP Server '{0}' is NOT in the desired state.
'@
