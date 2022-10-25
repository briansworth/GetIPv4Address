#requires -Version 2.0
function Find-MTUSize 
{
  <#
      .SYNOPSIS
      Returns the MTU size on your network

      .DESCRIPTION
      This automates the manual ping test, guess, subtract, test, guess, test again

      .PARAMETER IpToPing
      IP Address to test against. An example is your gateway

      .EXAMPLE
      Get-MTU -IpToPing 192.168.0.1
      Will ping the ip and return the MTU size

      .NOTES
      The program adds 28 to the final number to account for 20 bytes for the IP header and 8 bytes for the ICMP Echo Request header

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-MTU

      .INPUTS
      IP Address as an ipaddress

      .OUTPUTS
      MTU as an Object
  #>


  param(
    [Parameter(Mandatory = $true,HelpMessage = 'IP Address to test against. An example is your gateway')]
    [ipaddress]$IpToPing
  )
  Begin{
    [int]$Script:UpperBoundPacketSize = 9000 #Jumbo Frame 
    $DecrementBy = @(100, 50, 1)
    $IpAddress = $IpToPing.ToString()
    function Test-Size
    {
      <#
          .SYNOPSIS
          Test size of MTU with Ping.exe
      #>

      param
      (
        [Parameter(Mandatory = $true)]
        [String]$IpAddress,

        [Parameter(Mandatory = $true)]
        [int]$UpperBoundPacketSize,

        [Parameter(Mandatory = $true)]
        [int]$DecrementBy
      )
      $PingOut = $null
      $SearchString = '*fragmented*'
      $Script:UpperBoundPacketSize  += $DecrementBy+100
      do 
      {
        $Script:UpperBoundPacketSize -= $DecrementBy
        Write-Verbose -Message ('Testing packet size {0}' -f $Script:UpperBoundPacketSize)
        $PingOut = & "$env:windir\system32\ping.exe" $IpAddress -n 1 -l $Script:UpperBoundPacketSize -f
      }
      while ($PingOut[2] -like $SearchString)
    }
  }
  Process{
    $DecrementBy | ForEach-Object -Process {
      Test-Size -IpAddress $IpAddress -UpperBoundPacketSize $Script:UpperBoundPacketSize -DecrementBy $_
    }
  }
  End{
    $MTU = [int]$Script:UpperBoundPacketSize + 28 # Add 28 to this number to account for 20 bytes for the IP header and 8 bytes for the ICMP Echo Request header
    Remove-Variable -Name UpperBoundPacketSize -Scope Global # This just cleans up the variable since it was in the Global scope
    
    New-Object -TypeName PSObject -Property @{
      MTU = $MTU
  }}
}