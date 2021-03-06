<#
    https://ru.wikipedia.org/wiki/Формула_Валлиса

PI   2   2   4   4   6   6   8   8   10   10   12   12   14   14   16   16   18   18   20   20   22   22   24   24   26   26   28   28   30   30   ...
-- = - . - . - . - . - . - . - . - . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . -- . ---
 2   1   3   3   5   5   7   7   9   9    11   11   13   13   15   15   17   17   19   19   21   21   23   23   25   25   27   27   29   29   31   ...

 #>


<#
"`n{0:n0} / {1:n0} = {2}" -f $a, $b, ($a / $b * 2)
# 2 602 199 086 312 968 903 720 960 000 / 1 687 568 062 633 590 601 135 546 875 = 3,0839634192318387042162348964
#>

[decimal] $pi = 2
for ([decimal]$i = 1; $i -lt 999999; $i++)  # точность ~= порядок - 1, т.е. для 10^5 точность будет 4 знака
{
    $pi *= ([decimal](2 * $i) / [decimal](2 * $i - 1)) * ([decimal](2 * $i) / [decimal](2 * $i + 1)) 
}

[System.Math]::PI
$pi
$pi.GetType()