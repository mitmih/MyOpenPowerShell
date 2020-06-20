# напарник загадывает любое число из известного сортированного набора чисел, например, от 0 до 7 включительно (т.е. 8-мь чисел)
# вы называете число и в ответ слышите: "угадал" / "больше" / "меньше"
# сколько чисел нужно НАЗВАТЬ, прежде, чем вы узнаете загаданное?
# 
# используя алгоритм двоичного поиска,
#   вы определяете нижнюю (l) и верхнюю (h) границы поиска,
#   называете число (m), находящееся посередине этих границ и, в зависимости от ответа ("угадал" / "больше" / "меньше"),
#   переносите одну из границ, чтобы назвать новое среднее число,
# вы узнаете загаданное число не более, чем за N вопросов, где N означает степерь 2-ки:
#   2^(N-1) < общее количество чисел <= 2^N
# 
# т.е. для 8 чисел это не более 3х вопросов ( 8 <= 2^3 )
# 
# $lst = @( 0, 1, 2, 3, 4, 5, 6, 7) ; $t = 7
# 
# l = 0
# h = 7
# 11111111111111111111111111111111111111111111111111111111111111111111111111111111
# 1     m = (l + h) / 2 = (0 + 7) / 2 = 3
# 1
# 1     l             h
# 1     0 1 2 3 4 5 6 7
# 1           m
# 1 это 3? - нет, больше! - ок, двигаем нижнюю границу сразу за серединку
# 1     l = m + 1 = 3 + 1 = 4
# 1     h = 7
# 
# 22222222222222222222222222222222222222222222222222222222222222222222222222222222
# 2     m = (4+7)/2 = 5
# 2
# 2             l     h
# 2     0 1 2 3 4 5 6 7
# 2               m
# 2 это 5? - нет, больше! - ок, снова двигаем нижнюю границу сразу за серединку
# 2     l = m + 1 = 5 + 1 = 6
# 2     h = 7
# 2     m = (6+7)/2 = 6
# 
# 33333333333333333333333333333333333333333333333333333333333333333333333333333333
# 3                 l h
# 3     0 1 2 3 4 5 6 7
# 3                 m
# 3 это 6? - нет, больше! - значит 7, т.к. остались только 6 и 7 и про 7 можно не спрашивать


function Search-Binary {
    param (
        [int[]] $lst,   # отсортированный список чисел
        $target         # целевое, т.е. загаданное, число
    )
    
    
    $low = 0  # нижняя граница поиска
    
    $high = $lst.Length - 1  # верхняя граница поиска
    
    $step = 0  # номер заданного вопроса
    
    while ($low -lt $high)  # цикл работает, пока границы отличаются друг от друга
    {
        $step++
        
        # нельзя, как в Python, просто взять и преобразовать число с плавающей точкой в целое
        #   [int]( ($low + $high) / 2 )
        # т.к. при таком преобразовании PoSh округлит результат не вниз, а до ближайшего чётного
        #   [int]( (0 + 5) / 2 ) # 2, ok
        #   [int]( (0 + 7) / 2 ) # 4, а ждали-то 3 ...
        # можно использовать специальные математические функции, например, [System.Math]::Truncate
        # но проще и быстрее сдвинуть сумму целых чисел вправо на 1 бит - эквивалент целочисленному делению на 2 :)
        #   (0 + 5) -shr 1  # 2, ok
        #   (0 + 7) -shr 1  # 3, ok
        $mid = ($low + $high) -shr 1
        
        if ($target -eq $lst[$mid])
        { # загаданное число совпало с серединкой |=> вернём количество вопросов
            return $step
        }
        elseif ($target -gt $lst[$mid])
        { # загаданное число больше серединки |=> ставим нижнюю границу сразу после серединки
            $low = $mid + 1
        }
        else
        { # загаданное число меньше серединки |=> ставим верхнюю границу сразу перед серединкой
            $high = $mid - 1
        }
    }
    
    # цикл завершился, а загаданное число вроде бы осталось неизвестным ...
    # 
    # на самом деле это не так, потому что в последний прогон цикла:
    #   во-первых, до проверки серединки, границы поиска указывали на пару соседних чисел (почти сомкнулись)
    #   во-вторых, серединка находится внутри границ и указывает на одно из этих двух чисел
    #   в-третьих, на вопрос "это серединка?" был ответ "больше" (или "меньше")
    #   т.е. границы поиска изменились последний раз и стали равны, что и завершило цикл
    # следовательно, искомое число уже известно и без дополнительного вопроса - это оставшееся число "не-серединка"
    # т.к. на нём сошлись границы поиска: $target = $lst[$high] = $lst[$low]
    # 
    # и это равенство можно использовать для проверки на честность - а было ли загаданное число из списка или нет? :)
    
    if ($target -eq $lst[$high] -and $target -eq $lst[$low])
    {  # все честно и искомое число стало известно методом исключения
        # "step={3}, `t target={0}, `t low={1}, `t high={2}" -f $target, $lst[$low], $lst[$high], $step | Write-Warning
        return $step
    }
    else
    {  # партнёр попался на нечестной игре :)
        "Catched! There is no '{0}' in '{1}' list. :)" -f $target, ($lst[0..-1] -join '..') | Write-Warning
        return $null
    }
}


<# рекурсивные образцы, рабочие но медленные...
# баловство с рекурсией происходило, пока не была написана референсная функция Search-Binary и не произведены замеры производительности:
#   во-первых рекурсия сама по себе медленнее из-за накладных расходов на вызов с другими аргументами и возврат по стеку вызовов
# 
#   во-вторых, конкретно в этих функциях используются куски массивов
#   (если цель в 1й половине списка, то работаем с ним, иначе работаем со 2й половиной), что тоже сильно замедляет их
#   в то время, как эталонная Search-Binary работает с одним конкретным (серединка) элементом списка и тягает весь или часть списка

function foo0 {
    param ( $lst, $target, $shift = 0 )
    
    if ($target -in $lst)
    {
        if ($lst.count -eq 1 -and $lst[-1] -eq $target)
        {
            return $shift
        }
        
        if ($target -in $lst[0..(($lst.Length -1) -shr 1)])
        {
            foo0 $lst[0..(($lst.Length -1) -shr 1)] $target ($shift + 1)
        }
        
        if ($target -in $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)])
        {
            foo0 $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)] $target ($shift + 1)
        }
    }
}

function foo1 {
    param ( $lst, $target, $shift = 0 )
    
    # if ($null -eq (Compare-Object -ReferenceObject @($target) -DifferenceObject $lst -SyncWindow 0)) { return $shift }
    if ($lst.count -eq 1 -and $lst[-1] -eq $target) { return $shift }
    
    if ($target -in $lst[0..(($lst.Length -1) -shr 1)])
    {
        return foo1 $lst[0..(($lst.Length -1) -shr 1)] $target ($shift + 1)
    }
    
    if ($target -in $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)])
    {
        return foo1 $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)] $target ($shift + 1)
    }
    
    return -1
}

function foo2 {
    param ( $lst, $target, $shift = 0 )
    
    while ($lst.count -gt 1)
    {
        if ($target -in $lst[0..(($lst.Length -1) -shr 1)])
        {
            $lst = $lst[0..(($lst.Length -1) -shr 1)]
        }
        elseif ($target -in $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)])
        {
            $lst = $lst[((($lst.Length -1) -shr 1) + 1)..($lst.Length -1)]
        }
        else {$shift-- ; break}
        
        $shift++
    }
    return $shift
}
#>


function Search-GRKBinary # by Oleg Glushko, modified to check steps count
{ # https://github.com/egonSchiele/grokking_algorithms/pull/106/commits/1f205a4b058d9cfc329cc342ec945f18aefd7d01
    param ($list, $item)

    # $low and $high keep track of which part of the list you'll search in.
    $low = 0;
    $high = $list.Length - 1;

    $step = 0  # modified to check steps count
    # While you haven't narrowed it down to one element ...
    while ($low -le $high)
	{
        $step++  # modified to check steps count
        # ... check the middle element
        $mid = [int](($low + $high) / 2);
        $guess = $list[$mid];
        # Found the item.
        if ($guess -eq $item)
        {
            return $step;  # modified to check steps count
        }
        # The guess was too high.
        if ($guess -gt $item)
        {
            $high = $mid - 1
        }
        # The guess was too low
        else
        {
            $low = $mid + 1
        }

    }

    # Item doesn't exist
    return -1;
}