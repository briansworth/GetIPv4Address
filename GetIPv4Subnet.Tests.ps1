Import-Module -Name ./GetIPv4Subnet.psm1 -Force

BeforeAll {
    function Assert-Ipv4SubnetIsEqual
    {
        param(
            [PSObject]$ReferenceSubnet
            ,
            [PSObject]$DifferenceSubnet
        )
        $properties = @(
            'CidrId',
            'NetworkId',
            'SubnetMask',
            'PrefixLength',
            'HostCount',
            'FirstHostIP',
            'LastHostIP',
            'Broadcast'
        )
        foreach ($property in $properties)
        {
            $refValue = $ReferenceSubnet.PSObject.Properties.Item($property)
            $diffValue = $DifferenceSubnet.PSObject.Properties.Item($property)
            if ($refValue.Value -ne $diffValue.Value)
            {
                $emsg = [string]::Format(
                    'Property: [{0}] mismatch. Reference: [{1}] != [{2}]',
                    $property,
                    $refValue.Value,
                    $diffValue.Value
                )
                throw $emsg
            }
        }
    }

    $subnet1 = [PSCustomObject]@{
        CidrId = '10.0.1.0/24';
        NetworkId = '10.0.1.0';
        SubnetMask = '255.255.255.0';
        PrefixLength = '24';
        HostCount = '254';
        FirstHostIP = '10.0.1.1';
        LastHostIP = '10.0.1.254';
        Broadcast = '10.0.1.255';
    }
    $subnet2 = [PSCustomObject]@{
        CidrId = '10.11.0.0/16';
        NetworkId = '10.11.0.0';
        SubnetMask = '255.255.0.0';
        PrefixLength = '16';
        HostCount = '65534';
        FirstHostIP = '10.11.0.1';
        LastHostIP = '10.11.255.254';
        Broadcast = '10.11.255.255';
    }
    $subnet3 = [PSCustomObject]@{
        CidrId = '172.22.32.0/20';
        NetworkId = '172.22.32.0';
        SubnetMask = '255.255.240.0';
        PrefixLength = '20';
        HostCount = '4094';
        FirstHostIP = '172.22.32.1';
        LastHostIP = '172.22.47.254';
        Broadcast = '172.22.47.255';
    }
    $subnet4 = [PSCustomObject]@{
        CidrId = '192.168.1.1/32';
        NetworkId = '192.168.1.1';
        SubnetMask = '255.255.255.255';
        PrefixLength = '32';
        HostCount = '0';
        FirstHostIP = $null;
        LastHostIP = $null;
        Broadcast = '192.168.1.1';
    }
}

Describe 'Convert-IPv4AddressToBinaryString' {
    BeforeAll {
        $convertTests = @(
            @{'IP' = '192.168.1.5'; 'Expected' = '11000000101010000000000100000101';}
            @{'IP' = '10.0.0.1'; 'Expected' = '00001010000000000000000000000001';}
            @{'IP' = '192.168.2.155'; 'Expected' = '11000000101010000000001010011011';}
            @{'IP' = '172.16.255.0'; 'Expected' = '10101100000100001111111100000000';}
        )
    }

    It 'Converts IPs to binary strings correctly' {
        foreach ($test in $convertTests)
        {
            Write-Verbose "Test IP: [$($test.IP)]" -Verbose
            Convert-IPv4AddressToBinaryString -IPAddress $test.IP | Should -BeExactly $test.Expected
        }
    }
}

Describe 'Get-IPv4Subnet' {
    BeforeAll {
        $subnetTests = @(
            @{'IP' = '10.0.1.0'; 'Prefix' = '24'; 'NetMask' = '255.255.255.0'; 'HostCount' = '254'; 'Example' = $subnet1;}
            @{'IP' = '10.0.1.253'; 'Prefix' = '24'; 'NetMask' = '255.255.255.0'; 'HostCount' = '234'; 'Example' = $subnet1;}
            @{'IP' = '10.11.0.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $subnet2;}
            @{'IP' = '10.11.1.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65500'; 'Example' = $subnet2;}
            @{'IP' = '10.11.200.162'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $subnet2;}
            @{'IP' = '10.11.255.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $subnet2;}
            @{'IP' = '172.22.32.0'; 'Prefix' = '20'; 'NetMask' = '255.255.240.0'; 'HostCount' = '4094'; 'Example' = $subnet3;}
            @{'IP' = '172.22.47.254'; 'Prefix' = '20'; 'NetMask' = '255.255.240.0'; 'HostCount' = '4090'; 'Example' = $subnet3;}
            @{'IP' = '192.168.1.1'; 'Prefix' = '32'; 'NetMask' = '255.255.255.255'; 'HostCount' = '0'; 'Example' = $subnet4;}
        )
    }

    It 'Returns correct subnet information with IP and Prefix' {
        foreach ($test in $subnetTests)
        {
            Write-Verbose "Test IP: [$($test.IP)]. Prefix: [$($test.Prefix)]" -Verbose
            $result = Get-IPv4Subnet -IPAddress $test.IP -PrefixLength $test.Prefix

            { Assert-Ipv4SubnetIsEqual -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }

    It 'Returns correct subnet information with the IP and Subnetmask' {
        foreach ($test in $subnetTests)
        {
            Write-Verbose "Test IP: [$($test.IP)]. Netmask: [$($test.NetMask)]" -Verbose
            $result = Get-IPv4Subnet -IPAddress $test.IP -SubnetMask $test.NetMask

            { Assert-Ipv4SubnetIsEqual -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }

    It 'Returns correct subnet information with the IP and HostCount' {
        foreach ($test in $subnetTests)
        {
            Write-Verbose "Test IP: [$($test.IP)]. HostCount: [$($test.HostCount)]" -Verbose
            $result = Get-IPv4Subnet -IPAddress $test.IP -HostCount $test.HostCount

            { Assert-Ipv4SubnetIsEqual -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }
}

Describe 'Add-IntToIPv4Address' {
    BeforeAll {
        $ipTests = @(
            @{'IP' = '10.0.0.0'; 'Int' = -1; 'Expected' = '9.255.255.255';}
            @{'IP' = '0.0.0.0'; 'Int' = 257; 'Expected' = '0.0.1.1';}
        )
    }

    It 'Successfully adds integers to an IP address' {
        foreach ($test in $ipTests)
        {
            Write-Verbose "Test IP: [$($test.IP)]. Integer: [$($test.Int)]" -Verbose
            Add-IntToIPv4Address -IPv4Address $test.IP -Integer $test.Int | Should -BeExactly $test.Expected
        }
    }

    It 'Throws if underflow occurs' {
        { Add-IntToIPv4Address -IPv4Address 0.0.0.0 -Integer -1 -ErrorAction Stop } | Should -Throw
    }

    It 'Throws if overflow occurs' {
        { Add-IntToIPv4Address -IPv4Address 255.255.255.255 -Integer 1 -ErrorAction Stop } | Should -Throw
    }
}

Describe 'Convert-NetMaskToCIDR' {
    BeforeAll {
        $script:cidrTests = @(
            @{'NetMask' = '255.255.255.255'; 'Expected' = '32';}
            @{'NetMask' = '255.255.255.252'; 'Expected' = '30';}
            @{'NetMask' = '255.255.255.248'; 'Expected' = '29';}
            @{'NetMask' = '255.255.255.240'; 'Expected' = '28';}
            @{'NetMask' = '255.255.255.224'; 'Expected' = '27';}
            @{'NetMask' = '255.255.255.192'; 'Expected' = '26';}
            @{'NetMask' = '255.255.255.0'; 'Expected' = '24';}
            @{'NetMask' = '255.255.128.0'; 'Expected' = '17';}
            @{'NetMask' = '255.255.0.0'; 'Expected' = '16';}
            @{'NetMask' = '255.254.0.0'; 'Expected' = '15';}
        )
    }

    It 'Successfully converts SubnetMask to CIDR prefix length' {
        foreach ($test in $script:cidrTests)
        {
            Write-Verbose "Netmask: [$($test.NetMask)]" -Verbose
            Convert-NetMaskToCIDR -SubnetMask $test.NetMask | Should -BeExactly $test.Expected
        }
    }

    It 'Throws an exception with invalid subnet mask' {
        $expected = "Invalid SubnetMask specified"

        foreach ($netmask in @('20.0.0.0', '255.0.255.0'))
        {
            { Convert-NetMaskToCIDR -SubnetMask $netmask -ErrorAction Stop } | Should -Throw "$expected *$netmask*"
        }
    }
}

Describe 'Convert-CIDRToNetMask' {
    It 'Successfully converts prefix length to subnet mask' {
        foreach ($test in $script:cidrTests)
        {
            Write-Verbose "Prefix: [$($test.Expected)]" -Verbose
            Convert-CIDRToNetMask -PrefixLength $test.Expected | Should -BeExactly $test.Netmask
        }
    }
}
