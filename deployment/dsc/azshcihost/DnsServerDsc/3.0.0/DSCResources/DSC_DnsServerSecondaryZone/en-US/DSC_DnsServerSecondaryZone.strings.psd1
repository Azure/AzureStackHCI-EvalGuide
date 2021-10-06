# culture="en-US"
ConvertFrom-StringData @'
    CheckingZoneMessage          = Checking DNS server zone with name {0} ...
    TestZoneMessage              = Named DNS server zone is {0} and it should be {1}
    RemovingZoneMessage          = Removing DNS server zone ...
    DeleteZoneMessage            = DNS server zone {0} is now absent
    CheckingSecondaryZoneMessage = Checking if the DNS server zone is a secondary zone ...
    AlreadySecondaryZoneMessage  = DNS server zone {0} is already a secondary zone
    NotSecondaryZoneMessage      = DNS server zone {0} is not a secondary zone but {1} zone
    AddingSecondaryZoneMessage   = Adding secondary DNS server zone  ...
    NewSecondaryZoneMessage      = DNS server secondary zone {0} is now present
    SetSecondaryZoneMessage      = DNS server zone {0} is now a secondary zone
    CheckPropertyMessage         = Checking DNS secondary server {0} ...
    NotDesiredPropertyMessage    = DNS server secondary zone {0} is not correct. Expected {1}, actual {2}
    DesiredPropertyMessage       = DNS server secondary zone {0} is correct
    SetPropertyMessage           = DNS server secondary zone {0} is set
'@
