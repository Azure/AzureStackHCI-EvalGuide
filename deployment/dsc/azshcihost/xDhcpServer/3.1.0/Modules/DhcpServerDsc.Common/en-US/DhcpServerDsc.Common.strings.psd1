# Localized resources for helper module DhcpServerDsc.Common.

ConvertFrom-StringData @'
    InvalidIPAddressFormat = Value of {0} property is not in a valid IP address format. Specify a valid IP address format and try again.
    InvalidIPAddressFamily = The IP address {0} is not a valid {1} address. Specify a valid IP address in {1} format and try again.
    InvalidTimeSpanFormat  = Value of {0} property is not in a valid timespan format. Specify the timespan in days.hrs:mins:secs format and try again.
    InvalidScopeIdSubnetMask = Value of byte {0} in {1} ({2}) is not valid. Binary AND with byte {0} in SubnetMask ({3}) should be equal to byte {0} in ScopeId ({4}).
    InvalidStartAndEndRangeMessage = Value of IPStartRange ({0}) and IPEndRange ({1}) are not valid. Start should be lower than end.
'@
