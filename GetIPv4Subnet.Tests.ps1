BeforeAll {
    function Assert-Ipv4SubnetEquals
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

    $allExamples = @()
    $example1 = [PSCustomObject]@{
        CidrId = '10.0.1.0/24';
        NetworkId = '10.0.1.0';
        SubnetMask = '255.255.255.0';
        PrefixLength = '24';
        HostCount = '254';
        FirstHostIP = '10.0.1.1';
        LastHostIP = '10.0.1.254';
        Broadcast = '10.0.1.255';
    }
    $example2 = [PSCustomObject]@{
        CidrId = '10.11.0.0/16';
        NetworkId = '10.11.0.0';
        SubnetMask = '255.255.0.0';
        PrefixLength = '16';
        HostCount = '65534';
        FirstHostIP = '10.11.0.1';
        LastHostIP = '10.11.255.254';
        Broadcast = '10.11.255.255';
    }
    $example3 = [PSCustomObject]@{
        CidrId = '172.22.32.0/20';
        NetworkId = '172.22.32.0';
        SubnetMask = '255.255.240.0';
        PrefixLength = '20';
        HostCount = '4094';
        FirstHostIP = '172.22.32.1';
        LastHostIP = '172.22.47.254';
        Broadcast = '172.22.47.255';
    }

    $allExamples += $example1
    $allExamples += $example2
    $allExamples += $example3
}

Describe 'Get-IPv4Subnet' {
    BeforeAll {
        $subnetTests = @(
            @{'IP' = '10.0.1.0'; 'Prefix' = '24'; 'NetMask' = '255.255.255.0'; 'HostCount' = '254'; 'Example' = $example1;}
            @{'IP' = '10.0.1.253'; 'Prefix' = '24'; 'NetMask' = '255.255.255.0'; 'HostCount' = '234'; 'Example' = $example1;}
            @{'IP' = '10.11.0.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $example2;}
            @{'IP' = '10.11.1.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65500'; 'Example' = $example2;}
            @{'IP' = '10.11.200.162'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $example2;}
            @{'IP' = '10.11.255.0'; 'Prefix' = '16'; 'NetMask' = '255.255.0.0'; 'HostCount' = '65534'; 'Example' = $example2;}
            @{'IP' = '172.22.32.0'; 'Prefix' = '20'; 'NetMask' = '255.255.240.0'; 'HostCount' = '4094'; 'Example' = $example3;}
            @{'IP' = '172.22.47.254'; 'Prefix' = '20'; 'NetMask' = '255.255.240.0'; 'HostCount' = '4090'; 'Example' = $example3;}
        )
    }

    It 'Returns correct subnet information with IP and Prefix' {
        foreach ($test in $subnetTests)
        {
            $result = Get-IPv4Subnet -IPAddress $test.IP -PrefixLength $test.Prefix

            { Assert-Ipv4SubnetEquals -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }

    It 'Returns correct subnet information with the IP and Subnetmask' {
        foreach ($test in $subnetTests)
        {
            $result = Get-IPv4Subnet -IPAddress $test.IP -SubnetMask $test.NetMask

            { Assert-Ipv4SubnetEquals -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }

    It 'Returns correct subnet information with the IP and HostCount' {
        foreach ($test in $subnetTests)
        {
            $result = Get-IPv4Subnet -IPAddress $test.IP -HostCount $test.HostCount

            { Assert-Ipv4SubnetEquals -ReferenceSubnet $result -DifferenceSubnet $test.Example } | Should -Not -Throw
        }
    }
}
