#!/usr/bin/env powershell
#requires -Version 2.0 -Modules Microsoft.PowerShell.Utility

Set-Location -ErrorAction Stop -LiteralPath $PSScriptRoot
Write-Output ('{0}.psd1' -f $((get-item (Get-Location).Path).Name))

$Major = 0     # Changes that cause the code to operate differently or large rewrites
$minor = 1     # When an individual module or function is added
$Patch = 2     # Small updates to a function or module.  Note: This goes to zero when minor is updated


$SplatSettings = @{
#Path = '{0}\{1}.psd1' -f $((get-item (Get-Location).Path).FullName), $((get-item (Get-Location).Path).Name)
Path = '{0}\{1}.psd1' -f $((get-item (Get-Location).Path).FullName), 'GetIPv4Subnet'
RootModule = 'loader.psm1'
Guid = "$(New-Guid)"
Author = 'Brian Farnsworth' 
CompanyName = 'CodeAndKeep.com'
ModuleVersion = '{0}.{1}.{2}' -f $Major,$minor,$Patch
Description = 'IT Admin network toolbox for Reference and Testing'
Copyright = '(c) Brian Farnsworth. All rights reserved.'
PowerShellVersion = '3.0'
NestedModules = 'Modules/GetIPv4Subnet.psm1','Modules/PingIpRange.psm1','Modules/TestMtuSize.psm1'
FunctionsToExport = @(
  'Add-IntToIPv4Address'
  'Convert-CIDRToNetMask'
  'Convert-IPv4AddressToBinaryString'
  'Convert-NetMaskToCIDR'
  'Get-CIDRFromHostCount'
  'Get-IPv4Subnet'
  'Ping-IpRange'
  'Get-SubnetCheatSheet'
  'Find-MtuSize'
)
AliasesToExport = @('pingr','SubnetList','ListSubnets','ToCIDR','ToMask')
ReleaseNotes = 'Fixing the manifest update script.  Removed the array "@()" from the NestedModules'
}

New-ModuleManifest @SplatSettings