# culture="en-US"
ConvertFrom-StringData @'
    CheckingZoneMessage                     = Checking DNS server zone with name '{0}' is '{1}'...
    AddingZoneMessage                       = Adding DNS server zone '{0}' ...
    RemovingZoneMessage                     = Removing DNS server zone '{0}' ...
    NotDesiredPropertyMessage               = DNS server zone property '{0}' is not correct. Expected '{1}', actual '{2}'
    SetPropertyMessage                      = DNS server zone property '{0}' is set
    CredentialRequiresComputerNameMessage   = The Credentials Parameter can only be used when ComputerName is also specified.
    DirectoryPartitionReplicationScopeError = A Directory Partition can only be specified when the Replication Scope is set to 'Custom'
'@
