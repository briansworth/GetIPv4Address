function Convert-IPv4AddresstoBinary
{
  <#
      .SYNOPSIS
      Converts an IP v4 Address to a binary string 

      .DESCRIPTION
      IPv4 Addresses are 32 bit addresses written in four bytes (Octets) separated by dots like 192.168.2.1.
      This function converts each of those Octets to binary, then concatinates those into a 32 bit string without the dots. 
 
      .EXAMPLE
      Convert-IPAddresstoBinary -IPAddress 4.3.2.1
      
      Returns:
      00000100000000110000001000000001

      .INPUTS
      v4 IpAddress

      .OUTPUTS
      String
  #>

  param
  (
    [Parameter(Mandatory,HelpMessage = 'v4 IP Address as "192.168.10.25"')]
    [ipaddress]$IPAddress
  )
  $addressBytes = $IPAddress.GetAddressBytes()

  $addressBytes | ForEach-Object -Process {
    $binary = $binary + $([convert]::toString($_,2).padleft(8,'0'))
  }
  return $binary
}

Function ConvertIPv4ToInt 
{
  [CmdletBinding()]
  Param(
    [String]$IPv4Address
  )
  Try
  {
    $IPAddress = [IPAddress]::Parse($IPv4Address)

    $bytes = $IPAddress.GetAddressBytes()
    [Array]::Reverse($bytes)

    [System.BitConverter]::ToUInt32($bytes,0)
  }
  Catch
  {
    Write-Error -Exception $_.Exception `
    -Category $_.CategoryInfo.Category
  }
}

Function ConvertIntToIPv4 
{
  [CmdletBinding()]
  Param(
    [uint32]$Integer
  )
  Try
  {
    $bytes = [System.BitConverter]::GetBytes($Integer)
    [Array]::Reverse($bytes)
    ([IPAddress]($bytes)).ToString()
  }
  Catch
  {
    Write-Error -Exception $_.Exception `
    -Category $_.CategoryInfo.Category
  }
}

Function Add-IntToIPv4Address 
{
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
  Param(
    [Parameter(Mandatory = $true)][String]$IPv4Address,

    [Parameter(Mandatory = $true)][int64]$Integer
  )
  Try
  {
    $ipInt = ConvertIPv4ToInt -IPv4Address $IPv4Address `
    -ErrorAction Stop
    $ipInt += $Integer

    ConvertIntToIPv4 -Integer $ipInt
  }
  Catch
  {
    Write-Error -Exception $_.Exception `
    -Category $_.CategoryInfo.Category
  }
}

Function Convert-CIDRToNetMask 
{
  <#
      .SYNOPSIS
      Converts a CIDR to a netmask

      .EXAMPLE
      Convert-CIDRToNetMask -PrefixLength 26
    
      Returns: 255.255.255.192/26

      .NOTES
      To convert back use "Convert-NetMaskToCIDR" 
  #>


  [CmdletBinding()]
  [Alias('ToMask')]
  Param(
    [ValidateRange(0,32)]
    [int16]$PrefixLength = 0
  )
  $bitString = ('1' * $PrefixLength).PadRight(32,'0')

  $strBuilder = New-Object -TypeName Text.StringBuilder

  for($i = 0;$i -lt 32;$i += 8)
  {
    $8bitString = $bitString.Substring($i,8)
    $null = $strBuilder.Append(('{0}.' -f [Convert]::ToInt32($8bitString,2)))
  }

  $strBuilder.ToString().TrimEnd('.')
}

Function Convert-NetMaskToCIDR 
{
  <#
      .SYNOPSIS
      Converts a netmask to a CIDR

      .EXAMPLE
      Convert-NetMaskToCIDR -SubnetMask 255.255.255.192
    
      Returns: 26

      .NOTES
      To convert back use "Convert-CIDRToNetMask" 
  #>


  [CmdletBinding()]
  [Alias('ToCIDR')]
  Param(
    [String]$SubnetMask = '255.255.255.0'
  )
  $byteRegex = '^(0|128|192|224|240|248|252|254|255)$'
  $invalidMaskMsg = ('Invalid SubnetMask specified [{0}]' -f $SubnetMask)
  Try
  {
    $netMaskIP = [IPAddress]$SubnetMask
    $addressBytes = $netMaskIP.GetAddressBytes()

    $strBuilder = New-Object -TypeName Text.StringBuilder

    $lastByte = 255
    foreach($byte in $addressBytes)
    {
      # Validate byte matches net mask value
      if($byte -notmatch $byteRegex)
      {
        Write-Error -Message $invalidMaskMsg `
        -Category InvalidArgument `
        -ErrorAction Stop
      }
      elseif($lastByte -ne 255 -and $byte -gt 0)
      {
        Write-Error -Message $invalidMaskMsg `
        -Category InvalidArgument `
        -ErrorAction Stop
      }

      $null = $strBuilder.Append([Convert]::ToString($byte,2))
      $lastByte = $byte
    }

    ($strBuilder.ToString().TrimEnd('0')).Length
  }
  Catch
  {
    Write-Error -Exception $_.Exception `
    -Category $_.CategoryInfo.Category
  }
}

function Get-CidrFromHostCount
{
  <#
      .SYNOPSIS
      Returns the CIDR number for a host count that will support the number of hosts you entered.
  #>
  [OutputType([Int])]
  param(
    [Parameter(Mandatory,ValueFromPipeline,HelpMessage = 'Integer between 1 - 4294967293')]
    [ValidateScript({
          $_ -gt 0
    })]
    [long]$HostCount
  )
  Begin{}
  Process{
    #Calculate available host addresses 
    $i = $MaxHosts = 0
    do
    {
      $i++
      $MaxHosts = ([math]::Pow(2,$i) - 2)
      $Prefix = 32 - $i 
    }
    until ($MaxHosts -ge $HostCount)
  }
  End{
    $PrefixLength = [PSCustomObject]@{
      PrefixLength = $Prefix
    }
    $PrefixLength
  }
}

function Get-SubnetCheatSheet
{
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
  [CmdletBinding()]
  [Alias('SubnetList','ListSubnets')]
  param(
    [Switch]$Raw
  )
  Begin{
    $OutputFormatting = '{0,4} | {1,13:#,#} | {2,13:#,#} | {3,-15}  '

    $CheatSheet = @()
  }
  Process{
    for($CIDR = 32;$CIDR -gt 0;$CIDR--)
    {
      $netmask = Convert-CIDRToNetMask -PrefixLength $CIDR
      $Addresses = [math]::Pow(2,32-$CIDR)
      $HostCount = (&{
          if($Addresses -le 2)
          {
            '0'
          }
          else
          {
            $Addresses -2
          }
      })
  
      $hash = [PsCustomObject]@{
        CIDR      = $CIDR
        NetMask   = $netmask
        HostCount = $HostCount
        Addresses = $Addresses
      }
      $CheatSheet += $hash
    }
  }
  End{
    if(-not $Raw)
    {
      $OutputFormatting  -f 'CIDR', 'Host Count', 'Addresses', 'NetMask'
      '='*55
      foreach($item in $CheatSheet)
      {
        $OutputFormatting -f $item.CIDR, $item.HostCount, $item.Addresses, $item.NetMask
      }
    }
    Else
    {
      $CheatSheet
    }
  }
}

function Ping-IpRange
{
  <#
      .SYNOPSIS
      Tests a range of Ip addresses.

      .DESCRIPTION
      A simple function to test a range of Ip addresses and returns the results to the screen. It returns an object, so you can sort and filter.

      .PARAMETER FirstAddress
      First address to test.

      .PARAMETER LastAddress
      Last address to test.

      .EXAMPLE
      Ping-IpRange -FirstAddress 192.168.0.20 -LastAddress 192.168.0.25 | sort available

      Address      Available
      -------      ---------
      192.168.0.22     False
      192.168.0.23     False
      192.168.0.25     False
      192.168.0.20      True
      192.168.0.21      True
      192.168.0.24      True
    
      .EXAMPLE
      Ping-IpRangeNew -FirstAddress 192.168.0.20 -LastAddress 192.168.0.50 | Where Available -EQ $true

      Address      Available
      -------      ---------
      192.168.0.20      True
      192.168.0.21      True
      192.168.0.24      True
      192.168.0.43      True


      .OUTPUTS
      Object to console
  #>
  [CmdletBinding()]
  [Alias("pingr")]
  Param(
    [Parameter(Mandatory,HelpMessage = 'Ip Address to start from',Position = 0)]
    [ipaddress]$FirstAddress,
    [Parameter(Mandatory,HelpMessage = 'Ip Address to stop at',Position = 1)]
    [ipaddress]$LastAddress
  )

  $Startip = ConvertIPv4ToInt -IPv4Address $FirstAddress.IPAddressToString
  $endip = ConvertIPv4ToInt -IPv4Address $LastAddress.IPAddressToString
  $PingRange = @()
    
  Try
  {
    $ProgressCount = $endip - $Startip
    $j = 0
    for($i = $Startip;$i -le $endip;$i++)
    {
      $ip = ConvertIntToIPv4 -Integer $i
      $Response = [PSCustomObject]@{
        Address   = $ip
        Available = (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeToLive 20)
      }

      Write-Progress -Activity ('Ping {0}' -f $ip) -PercentComplete ($j / $ProgressCount*100)
      $j++

      $PingRange += $Response
    }
  }
  Catch
  {
    Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
  }
  $PingRange
}

Function Get-IPv4Subnet 
{
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
  [CmdletBinding(DefaultParameterSetName = 'PrefixLength')]
  Param(
    [Parameter(Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ValueFromRemainingArguments = $false,
        HelpMessage = 'IP Address in the form of XXX.XXX.XXX.XXX',
    Position = 0)]
    [IPAddress]$IPAddress,

    [Parameter(Position = 1,ParameterSetName = 'PrefixLength',ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true)]
    [Int16]$PrefixLength = 24,

    [Parameter(Mandatory = $true,Position = 1,ParameterSetName = 'SubnetMask')]
    [IPAddress]$SubnetMask,
    
    [Parameter(Mandatory = $true,Position = 1,ParameterSetName = 'Hosts',
    HelpMessage = 'Number of hosts in need of IP Addresses')]
    [Int64]$HostCount
  )
  Begin{}
  Process{
    Try
    {
      if($PrefixLength)
      {
        $MaxHosts = [math]::Pow(2,(32-$PrefixLength)) - 2
      }
      if($HostCount)
      {
        $PrefixLength = (Get-CidrFromHostCount -HostCount $HostCount).PrefixLength
        $MaxHosts = [math]::Pow(2,(32-$PrefixLength)) - 2
      }
      
      if($PSCmdlet.ParameterSetName -eq 'SubnetMask')
      {
        $PrefixLength = Convert-NetMaskToCIDR -SubnetMask $SubnetMask `
        -ErrorAction Stop
      }
      else
      {
        $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength `
        -ErrorAction Stop
      }
      
      $netMaskInt = ConvertIPv4ToInt -IPv4Address $SubnetMask     
      $ipInt = ConvertIPv4ToInt -IPv4Address $IPAddress
      
      $networkID = ConvertIntToIPv4 -Integer ($netMaskInt -band $ipInt)

      $broadcast = Add-IntToIPv4Address -IPv4Address $networkID `
      -Integer ($MaxHosts+1)

      $firstIP = Add-IntToIPv4Address -IPv4Address $networkID -Integer 1
      $lastIP = Add-IntToIPv4Address -IPv4Address $broadcast -Integer (-1)

      if($PrefixLength -eq 32)
      {
        $broadcast = $networkID
        $firstIP = $null
        $lastIP = $null
        $MaxHosts = 0
      }

      $outputObject = New-Object -TypeName PSObject 

      $memberParam = @{
        InputObject = $outputObject
        MemberType  = 'NoteProperty'
        Force       = $true
      }
      Add-Member @memberParam -Name CidrID -Value ('{0}/{1}' -f $networkID, $PrefixLength)
      Add-Member @memberParam -Name NetworkID -Value $networkID
      Add-Member @memberParam -Name SubnetMask -Value $SubnetMask
      Add-Member @memberParam -Name PrefixLength -Value $PrefixLength
      Add-Member @memberParam -Name HostCount -Value $MaxHosts
      Add-Member @memberParam -Name FirstHostIP -Value $firstIP
      Add-Member @memberParam -Name LastHostIP -Value $lastIP
      Add-Member @memberParam -Name Broadcast -Value $broadcast

      Write-Output -InputObject $outputObject
    }
    Catch
    {
      Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
    }
  }
  End{}
}

# The line below "Export-ModuleMember" must be the last line in the script.
Export-ModuleMember -Alias * -Function Get-IPv4Subnet, Convert-NetMaskToCIDR, Convert-CIDRToNetMask, Add-IntToIPv4Address, Get-CidrFromHostCount, Convert-IPv4AddressToBinary, Get-SubnetCheatSheet, Ping-IpRange

