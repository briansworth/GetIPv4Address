# briansworth.GetIPv4Address
IP addressing, subnets and so much more

Get-SubnetCheatSheet 
Get-IPv4Subnet
Convert-NetMaskToCIDR
Convert-CIDRToNetMask
Add-IntToIPv4Address
Get-CidrFromHostCount
Convert-IPv4AddressToBinaryString


<#
      .SYNOPSIS
      Converts an IP v4 Address to Binary String 
  #>

<#
      .SYNOPSIS
      Add an integer to an IP Address and get the new IP Address.

      .DESCRIPTION
      Add an integer to an IP Address and get the new IP Address.

      .PARAMETER IPv4Address
      The IP Address to add an integer to.

      .PARAMETER Integer
      An integer to add to the IP Address. Can be a positive or negative number.

      .EXAMPLE
      Add-IntToIPv4Address -IPv4Address 10.10.0.252 -Integer 10

      10.10.1.6

      Description
      -----------
      This command will add 10 to the IP Address 10.10.0.1 and return the new IP Address.

      .EXAMPLE
      Add-IntToIPv4Address -IPv4Address 192.168.1.28 -Integer -100

      192.168.0.184

      Description
      -----------
      This command will subtract 100 from the IP Address 192.168.1.28 and return the new IP Address.
  #>

<#
      .SYNOPSIS
      Converts a CIDR to a netmask

      .EXAMPLE
      Convert-CIDRToNetMask -PrefixLength 26
    
      Returns: 255.255.255.192/26

      .NOTES
      To convert back use "Convert-NetMaskToCIDR" 
  #>

<#
      .SYNOPSIS
      Converts a netmask to a CIDR

      .EXAMPLE
      Convert-NetMaskToCIDR -SubnetMask 255.255.255.192
    
      Returns: 26

      .NOTES
      To convert back use "Convert-CIDRToNetMask" 
  #>

<#
      .SYNOPSIS
      Returns the CIDR number for a host count that will support the number of hosts you entered.
  #>

<#
      .SYNOPSIS
      Creates a little cheatsheet for subnets.

      .DESCRIPTION
      Creates a little cheatsheet for subnets to the console or send it to a file such as a CSV for opening in a spreadsheet.

      .PARAMETER ToConsole
      Sends the whole formatted table to the console

      .EXAMPLE
      Get-SubnetCheatSheet | Where-Object {($_.CIDR -gt 15) -and ($_.CIDR -lt 22)} | Select-Object CIDR,Netmask

      .EXAMPLE
      Get-SubnetCheatSheet -ToConsole 

      .EXAMPLE
      Get-SubnetCheatSheet | Export-Csv .\SubnetSheet.csv -NoTypeInformation
      Sends the data to a csv file

      .EXAMPLE
      Get-SubnetCheatSheetGet-SubnetTable | Where-Object {$_.NetMask -like '255.255.*.0' }
      Selects only one class of subnets
  #>

<#
      .SYNOPSIS
      Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length

      .DESCRIPTION
      Get information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length

      .PARAMETER IPAddress
      The IP Address to use for determining subnet information. 

      .PARAMETER PrefixLength
      The prefix length of the subnet.

      .PARAMETER SubnetMask
      The subnet mask of the subnet.

      .EXAMPLE
      Get-IPv4Subnet -IPAddress 192.168.34.76 -SubnetMask 255.255.128.0

      CidrID       : 192.168.0.0/17
      NetworkID    : 192.168.0.0
      SubnetMask   : 255.255.128.0
      PrefixLength : 17
      HostCount    : 32766
      FirstHostIP  : 192.168.0.1
      LastHostIP   : 192.168.127.254
      Broadcast    : 192.168.127.255

      Description
      -----------
      This command will get the subnet information about the IPAddress 192.168.34.76, with the subnet mask of 255.255.128.0

      .EXAMPLE
      Get-IPv4Subnet -IPAddress 10.3.40.54 -PrefixLength 25

      CidrID       : 10.3.40.0/25
      NetworkID    : 10.3.40.0
      SubnetMask   : 255.255.255.128
      PrefixLength : 25
      HostCount    : 126
      FirstHostIP  : 10.3.40.1
      LastHostIP   : 10.3.40.126
      Broadcast    : 10.3.40.127

      Description
      -----------
      This command will get the subnet information about the IPAddress 10.3.40.54, with the subnet prefix length of 25.
      Prefix length specifies the number of bits in the IP address that are to be used as the subnet mask.

  #>
