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
