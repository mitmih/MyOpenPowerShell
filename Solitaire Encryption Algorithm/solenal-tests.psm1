function Test-EncryptDecrypt {
    param ($text)
    
    $test = [ordered] @{}
    
    for ($i = 0; $i -lt 55; $i++)
    {
        $gamma = ("$i " * $text.Length).Trim().Split(' ')
        
        $enc = ConvertTo-Encrypted -KeyStream $gamma -text $text
        
        $dec = ConvertTo-Decrypted -KeyStream $gamma -text $enc

        $test[$text -eq $dec] += @($gamma[0])
    }
    
    if ($null -ne $test[$false])
    {
        return "`n- test FAILED`nfailed gamma`t" + ($test[$false] -join ' ') + "`n" + "passed gamma`t" + ($test[$true] -join ' ') + "`n"
    }
    else
    {
        return "`n+ test PASSED`n"
    }
}
