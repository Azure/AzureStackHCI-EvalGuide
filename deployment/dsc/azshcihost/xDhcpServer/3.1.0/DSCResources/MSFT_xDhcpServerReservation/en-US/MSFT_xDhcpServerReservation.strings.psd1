# Localized resources for en-US.

ConvertFrom-StringData @'
    GetServerReservationMessage = Get the current state of the server reservation with scope id '{0}'.
    SetServerReservationMessage = Changing the server reservation with scope id '{0}' to the desired state.
    TestServerReservationMessage = Evaluating the server reservation with scope id '{0}' if it is in the desired state.
    InvalidScopeIDMessage = DHCP server scopeID {0} is not valid. Supply a valid scopeID and try again
    CheckingReservationMessage = Checking DHCP server reservation in scope id {0} for IP address {1} ...
    TestReservationMessage = DHCP server reservation in the given scope id for the IP address is {0} and it should be {1}
    RemovingReservationMessage = Removing DHCP server reservation from scope id {0} for MAC address {1} ...
    DeleteReservationMessage = DHCP server reservation for the given MAC address is now absent
    AddingReservationMessage = Adding DHCP server reservation with the given IP address ...
    SetReservationMessage = DHCP server reservation in the given scope id for the IP address {0} is now present
    CheckPropertyMessage = Checking DHCP server reservation {0} for the given ipaddress ...
    NotDesiredPropertyMessage = DHCP server reservation for the given ipaddress doesn't have correct {0}. Expected {1}, actual {2}
    DesiredPropertyMessage = DHCP server reservation {0} for the given ipaddress is correct.
    SetPropertyMessage = DHCP server reservation {0} for the given ipaddress is set.
    DhcpServerReservationFailure = Failed to add the reservation for the scope id '{0}'.
'@
