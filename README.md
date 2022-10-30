# GetIPv4Address
I wanted a simple command that would give me the basic subnet information I commonly want. Identifying the Network ID was tedious, as was converting an IP / Subnet to CIDR notation and vice-versa. https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/

Since that time it has grown to include: 
- Get-IPv4Subnet
- Add-IntToIPv4Address 
- Convert-IPv4AddressToBinaryString
- Convert-CIDRToNetMask
- Convert-NetMaskToCIDR
- Get-SubnetCheatSheet
- Find-MTUSize
- Ping-IpRange

Now the purpose of this module is to provide a network toolbox for reference and testing IP addressing, subnets and more.  For more information about any of the functions use the  `Get-Help` cmdlet.



#### Get-IPv4Subnet
The primary function for this tools set.  The function gets information about an IPv4 subnet based on an IP Address and a subnet mask or prefix length

      CidrID       : 192.168.0.0/17
      NetworkID    : 192.168.0.0
      SubnetMask   : 255.255.128.0
      PrefixLength : 17
      HostCount    : 32766
      FirstHostIP  : 192.168.0.1
      LastHostIP   : 192.168.127.254
      Broadcast    : 192.168.127.255
 
 
 
#### Add-IntToIPv4Address
Adds an integer to an IP Address and get the new IP Address.  This is helpful when you are trying to get a range.        An integer to add to the IP Address. Can be a positive or negative number.

	10.10.0.252 + 100 = 10.10.1.96


#### Convert-IPv4AddressToBinaryString
Converts an IP v4 Address to Binary String 

    192.168.1.5 = 11000000101010000000000100000101


#### Convert-CIDRToNetMask
Converts a CIDR to a netmask 

    /26 = 255.255.255.192


#### Convert-NetMaskToCIDR 
Converts a netmask to a CIDR

    255.255.255.192 = /26


#### Get-SubnetCheatSheet
Creates a little cheatsheet for subnets to the console or send it to a file such as a CSV for opening in a spreadsheet.

    CIDR |    Host Count |     Addresses | NetMask       
    ========================================================
      32 |             0 |             1 | 255.255.255.255 | 
      31 |             0 |             2 | 255.255.255.254 | 
      30 |             2 |             4 | 255.255.255.252 | 
      29 |             6 |             8 | 255.255.255.248 | 
      28 |            14 |            16 | 255.255.255.240 | 
      27 |            30 |            32 | 255.255.255.224 | 
      26 |            62 |            64 | 255.255.255.192 | 



#### Find-MTUSize
Finds the MTU size being used on the network.

```
MTU
----
1500
```


#### Ping-IpRange
Pings through the range of IP addresses based on the First and Last Address provided.

      Address      Available
      -------      ---------
      192.168.0.22     False
      192.168.0.23     False
      192.168.0.25     False
      192.168.0.20      True
      192.168.0.21      True
      192.168.0.24      True
      

