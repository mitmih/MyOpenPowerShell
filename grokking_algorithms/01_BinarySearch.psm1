# напарник загадывает любое число из известного сортированного набора чисел, например, от 0 до 7 включительно (т.е. 8-мь чисел)
# вы называете число и в ответ слышите "угадал" / "больше" / "меньше"
# сколько раз вам нужно назвать числа, прежде, чем вы узнаете загаданное?
# используя алгоритм двоичного поиска, когда вы всегда назваете среднее число
# и, в зависимости от ответа, переносите нижнюю или верхнюю границу, чтобы назвать новое среднее число
# вы узнаете загаданное число не более, чем за N вопросов
# где N означает степерь 2-ки:
#   2^(N-1) < общее количество чисел <= 2^N
# т.е. для 8 чисел это не более 3х вопросов ( 8 <= 2^3 )
# 
# $lst = @( 0, 1, 2, 3, 4, 5, 6, 7) ; $t = 7
# 
# 11111111111111111111111111111111111111111111111111111111111111111111111111111111
# 1     l = 0
# 1     h = 7
# 1     m = (l + h) / 2 = (0 + 7) / 2 = 3
# 1
# 1     l             h
# 1     0 1 2 3 4 5 6 7
# 1           m
# 1?: это 3? - нет, больше! - ок, двигаем нижнюю границу сразу за серединку
# 1     l = m + 1 = 3 + 1 = 4
# 1     h = 7
# 1     m = (4+7)/2 = 5
# 
# 22222222222222222222222222222222222222222222222222222222222222222222222222222222
# 2             l     h
# 2     0 1 2 3 4 5 6 7
# 2               m
# 2?: это 5? - нет, больше! - ок, снова двигаем нижнюю границу сразу за серединку
# 2     l = m + 1 = 5 + 1 = 6
# 2     h = 7
# 2     m = (6+7)/2 = 6
# 
# 33333333333333333333333333333333333333333333333333333333333333333333333333333333
#                   l h
#       0 1 2 3 4 5 6 7
#                   m
# ?3: это 6? - нет, больше! - значит 7, т.к. остались только 6 и 7 и про 7 можно не спрашивать


function Search-Binary {
    param (
        [int[]] $lst,   # отсортированный список чисел
        $target         # целевое, т.е. загаданное, число
    )
    
    
    if ($target -notin $lst) { return -1 }  # проверка на честность: загадывать можно только числа из списка
    
    $low = 0  # нижняя граница поиска
    
    $high = $lst.Length - 1  # верхняя граница поиска
    
    $step = 0  # номер заданного вопроса
    
    while ($low -lt $high)  # цикл работает, пока границы отличаются друг от друга
    {
        $step++
        
        # нельзя, как в Python, просто преобразовать в целое [int]( ($low + $high) / 2 )
        # т.к. при преобразовании [Double] в [Int32] PoSh округляет до ближайшего чётного
        #   [int]( (0 + 5) / 2 ) # 2, ok
        #   [int]( (0 + 7) / 2 ) # 4, а ждали-то 3 ...
        # для округления вниз к ближайшему целому можно использовать специальные математические функции, нарпимер, [System.Math]::Truncate
        # но проще вычислить серединку сдвигом вправо на 1 бит (целочисленное деление на 2)
        #   (0 + 5) -shr 1  # 2, ok
        #   (0 + 7) -shr 1  # 3, ok
        $mid = ($low + $high) -shr 1
        
        if ($target -eq $lst[$mid])
        { # загаданное число совпало с серединкой |=> вернём количество вопросов
            return $step
        }
        elseif ($target -gt $lst[$mid])
        { # загаданное число больше серединки |=> сдвигаем нижнюю границу после серединки
            $low = $mid + 1
        }
        else
        { # загаданное число меньше серединки |=> сдвигаем верхнюю границу перед серединкой
            $high = $mid - 1
        }
    }
    
    # цикл завершился, а загаданное число вроде бы осталось неизвестным ...
    # 
    # на самом деле это не так, потому, что в последний прогон цикла:
    #   в-первых, до проверки серединки, границы поиска указывали на пару соседних чисел (почти сомкнулись)
    #   во-вторых, серединка находится внутри границ и указывает на одно из двух чисел
    #   в-третьих, на вопрос "это серединка?" был ответ "больше" (или "меньше")
    #   т.е. границы поиска изменились последний раз и стали равны, что завершило цикл
    # следовательно, искомое число известно без дополнительного вопроса, это не-серединка
    # его можно назвать утвердительно - на нём сошлись границы поиска
    #   $lst[$high], оно же $lst[$low]
    # 
    # убедимся в этом:
    "step={3}, `t target={0}, `t low={1}, `t high={2}" -f $target, $lst[$low], $lst[$high], $step | Write-Warning
    # 
    # и вернём количество ЗАДАННЫХ (т.е. спрошенных у напарника) чисел :)
    return $step
}


<# рекурсивные образцы, рабочие но медленные...
# баловство с рекурсией происходило, пока не была написана референсная функция Search-Binary и не произведены замеры производительности:
#   во-первых рекурсия сама по себе медленнее, видимо из-за накладных расходов на новый вызов с другими аргументами и возврат по стеку вызово
#   во-вторых, конкретно в этих функциях используются куски массивов (если цель в 1й половине списка, то работаем с ним, иначе работаем со 2й половиной), и это тоже сильно замедляет их, в то время, как эталонная Search-Binary работает с одним конкретным (серединка) элементом списка и тягает весь или часть списка туда-сюда

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