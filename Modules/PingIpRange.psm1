#requires -Version 3.0 
#-module ConvertIPv4ToInt, ConvertIntToIPv4, Add-IntToIPv4Address
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
