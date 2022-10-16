function Convert-IPv4AddressToBinaryString
{
  <#
      .SYNOPSIS
      Converts an IPv4 Address to Binary String

      .PARAMETER IPAddress
      The IP Address to convert to a binary string representation

      .EXAMPLE
      Convert-IPv4AddressToBinaryString -IPAddress 10.130.1.52
  #>
  Param(
    [IPAddress]$IPAddress = '0.0.0.0'
  )
  $addressBytes = $IPAddress.GetAddressBytes()

  $strBuilder = New-Object -TypeName Text.StringBuilder
  foreach ($byte in $addressBytes)
  {
    $8bitString = [Convert]::ToString($byte, 2).PadLeft(8, '0')
    $null = $strBuilder.Append($8bitString)
  }
  return $strBuilder.ToString()
}

function Get-IPv4Subnet
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
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      ValueFromRemainingArguments = $false,
      HelpMessage = 'IP Address in the form of XXX.XXX.XXX.XXX',
      Position = 0
    )]
    [IPAddress]$IPAddress
    ,
    [Parameter(
      Position = 1,
      ParameterSetName = 'PrefixLength',
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true
    )]
    [Int16]$PrefixLength = 24
    ,
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'SubnetMask')]
    [IPAddress]$SubnetMask
    ,
    [Parameter(
      Mandatory = $true,
      Position = 1,
      ParameterSetName = 'Hosts',
      HelpMessage = 'Number of hosts in need of IP Addresses'
    )]
    [Int64]$HostCount
  )
  begin
  {
  }
  process
  {
    try
    {
      if ($PSCmdlet.ParameterSetName -eq 'SubnetMask')
      {
        $PrefixLength = Convert-NetMaskToCIDR -SubnetMask $SubnetMask `
          -ErrorAction Stop
      }
      else
      {
        $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength `
          -ErrorAction Stop
      }
      if ($PSCmdlet.ParameterSetName -eq 'Hosts')
      {
        $PrefixLength = (Get-CidrFromHostCount -HostCount $HostCount).PrefixLength
        $SubnetMask = Convert-CIDRToNetMask -PrefixLength $PrefixLength `
          -ErrorAction Stop
      }
      $maxHosts = [math]::Pow(2, (32 - $PrefixLength)) - 2

      $netMaskInt = ConvertIPv4ToInt -IPv4Address $SubnetMask
      $ipInt = ConvertIPv4ToInt -IPv4Address $IPAddress

      $networkID = ConvertIntToIPv4 -Integer ($netMaskInt -band $ipInt)

      $broadcast = Add-IntToIPv4Address -IPv4Address $networkID `
        -Integer ($maxHosts + 1)

      $firstIP = Add-IntToIPv4Address -IPv4Address $networkID -Integer 1
      $lastIP = Add-IntToIPv4Address -IPv4Address $broadcast -Integer (-1)

      if ($PrefixLength -eq 32)
      {
        $broadcast = $networkID
        $firstIP = $null
        $lastIP = $null
        $maxHosts = 0
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
      Add-Member @memberParam -Name HostCount -Value $maxHosts
      Add-Member @memberParam -Name FirstHostIP -Value $firstIP
      Add-Member @memberParam -Name LastHostIP -Value $lastIP
      Add-Member @memberParam -Name Broadcast -Value $broadcast

      Write-Output -InputObject $outputObject
    }
    catch
    {
      Write-Error -Exception $_.Exception `
        -Category $_.CategoryInfo.Category
    }
  }
}

function Add-IntToIPv4Address
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
  param(
    [Parameter(Mandatory = $true)]
    [String]$IPv4Address
    ,
    [Parameter(Mandatory = $true)]
    [int64]$Integer
  )
  try
  {
    $ipInt = ConvertIPv4ToInt -IPv4Address $IPv4Address `
      -ErrorAction Stop
    $ipInt += $Integer

    return (ConvertIntToIPv4 -Integer $ipInt)
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

function Convert-CIDRToNetMask
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
  param(
    [ValidateRange(0, 32)]
    [int16]$PrefixLength = 0
  )
  $bitString = ('1' * $PrefixLength).PadRight(32, '0')
  $strBuilder = New-Object -TypeName Text.StringBuilder

  for ($i = 0; $i -lt 32; $i += 8)
  {
    $8bitString = $bitString.Substring($i, 8)
    $null = $strBuilder.Append(('{0}.' -f [Convert]::ToInt32($8bitString, 2)))
  }

  return $strBuilder.ToString().TrimEnd('.')
}

function Convert-NetMaskToCIDR
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
  param(
    [String]$SubnetMask = '255.255.255.0'
  )
  $byteRegex = '^(0|128|192|224|240|248|252|254|255)$'
  $invalidMaskMsg = ('Invalid SubnetMask specified [{0}]' -f $SubnetMask)
  try
  {
    $netMaskIP = [IPAddress]$SubnetMask
    $addressBytes = $netMaskIP.GetAddressBytes()

    $strBuilder = New-Object -TypeName Text.StringBuilder

    $lastByte = 255
    foreach ($byte in $addressBytes)
    {
      # Validate byte matches net mask value
      if ($byte -notmatch $byteRegex)
      {
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }
      elseif ($lastByte -ne 255 -and $byte -gt 0)
      {
        Write-Error -Message $invalidMaskMsg `
          -Category InvalidArgument `
          -ErrorAction Stop
      }

      $null = $strBuilder.Append([Convert]::ToString($byte, 2))
      $lastByte = $byte
    }

    return ($strBuilder.ToString().TrimEnd('0')).Length
  }
  catch
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
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      HelpMessage = 'Integer between 1 - 4294967293'
    )]
    [UInt32]$HostCount
  )
  begin
  {
  }
  process
  {
    #Calculate available host addresses
    $i = $maxHosts = 0
    $prefix = 32
    while ($maxHosts -ge $HostCount)
    {
      if ($HostCount -eq 0)
      {
        break
      }
      $i++
      $maxHosts = ([math]::Pow(2, $i) - 2)
      $prefix = 32 - $i
    }
    $prefixLength = [PSCustomObject]@{
      PrefixLength = $prefix;
    }
    return $prefixLength
  }
}

function Get-SubnetCheatSheet
{
  <#
      .SYNOPSIS
      Creates a little cheatsheet for subnets.

      .DESCRIPTION
      Creates and send a cheatsheet for subnets to the console or send it to a file such as a CSV for opening in a spreadsheet.
      The default is formated for the console.  

      .PARAMETER Raw
      Use this parameter to output an object for more manipulation

      .EXAMPLE
      Get-SubnetCheatSheet  

      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Where-Object {($_.CIDR -gt 15) -and ($_.CIDR -lt 22)} | Select-Object CIDR,Netmask
      
      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Export-Csv .\SubnetSheet.csv -NoTypeInformation
      Sends the data to a csv file

      .EXAMPLE
      Get-SubnetCheatSheet -Raw | Where-Object {$_.NetMask -like '255.255.*.0' }
      Selects only one class of subnets

      .Example
      Get-SubnetCheatSheet | Out-Printer -Name (Get-Printer | Out-GridView -PassThru).Name 
  #>
  [CmdletBinding()]
  [Alias('SubnetList', 'ListSubnets')]
  param(
    [Switch]$Raw
  )
  begin
  {
    $OutputFormatting = '{0,4} | {1,13:#,#} | {2,13:#,#} | {3,-15}  '

    $CheatSheet = @()
  }
  process
  {
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
  end
  {
    if(-not $Raw)
    {
      $OutputFormatting  -f 'CIDR', 'Host Count', 'Addresses', 'NetMask'
      '='*55
      foreach($item in $CheatSheet)
      {
        $OutputFormatting -f $item.CIDR, $item.HostCount, $item.Addresses, $item.NetMask
      }
    }
    else
    {
      $CheatSheet
    }
  }
}


# Non-Published Functions
function ConvertIPv4ToInt
{
  [CmdletBinding()]
  param(
    [String]$IPv4Address
  )
  try
  {
    $ipAddress = [IPAddress]::Parse($IPv4Address)

    $bytes = $IPAddress.GetAddressBytes()
    [Array]::Reverse($bytes)

    return [BitConverter]::ToUInt32($bytes, 0)
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

function ConvertIntToIPv4
{
  [CmdletBinding()]
  param(
    [uint32]$Integer
  )
  try
  {
    $bytes = [BitConverter]::GetBytes($Integer)
    [Array]::Reverse($bytes)
    ([IPAddress]($bytes)).ToString()
  }
  catch
  {
    Write-Error -Exception $_.Exception `
      -Category $_.CategoryInfo.Category
  }
}

