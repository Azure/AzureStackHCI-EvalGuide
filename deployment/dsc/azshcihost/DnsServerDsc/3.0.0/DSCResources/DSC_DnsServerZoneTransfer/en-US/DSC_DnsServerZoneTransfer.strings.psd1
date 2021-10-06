# culture="en-US"
ConvertFrom-StringData @'
    CheckingZoneMessage       = Checking the current zone transfer for DNS server zone {0} ...
    DesiredZoneMessage        = Current zone transfer settings for the given DNS server zone is correctly set to {0}
    NotDesiredZoneMessage     = DNS server zone transfer settings is not correct. Expected {0}, actual {1}
    SetZoneMessage            = Current zone transfer setting for DNS server zone {0} is set to {1}
    NotDesiredPropertyMessage = DNS server zone transfer secondary servers are not correct. Expected {0}, actual {1}
    SettingPropertyMessage    = Setting DNS server zone transfer secondary servers to {0} ...
    SetPropertyMessage        = DNS server zone transfer secondary servers are set
'@
