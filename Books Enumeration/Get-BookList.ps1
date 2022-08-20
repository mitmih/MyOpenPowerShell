#Requires   -Version    7.0
#Requires   -PSEdition  Core

# файловый объект скрипта
$me = Get-Item -Path $Script:PSCommandPath

# все файлы из вложенных папок
$SubDirFiles = Get-ChildItem -Recurse -Path $me.Directory -Exclude '*.ps1', '*.csv', '*.xls*'

# таблица с книгами
$lst = [System.Collections.ArrayList] @()

# наиболее важные расширения файлов книг
$ext = [System.Collections.ArrayList] @(
    '.mobi'
    '.epub'
    '.pdf'
    # '.fb2'
    # '.fb3'
    # '.jpg'
    '.mp4'
    # '.opf'
    '.txt'
    '.url'
    '.zip'
)

# # добавляем все остальные расширения в набор - каждое расширение будет полем (колонкой) в таблице книг
# $SubDirFiles |
#     Where-Object {$_.Mode -ne 'd----'} |
#     Group-Object -Property 'Extension' |
#     Select-Object -ExpandProperty 'Name' |
#     ForEach-Object { if ($_ -notin $ext) { $null = $ext.Add($_) } }

# составляем список книг
foreach ( $g in $SubDirFiles |
    Where-Object {$_.Mode -ne 'd----'} |
    Select-Object -Property *, @{ 'n' = 'Book' ; 'e' = {($_.BaseName -split '\.')[0..1] -join '.'} } |
    Group-Object -Property 'Book' )
{
    # поле 'BookDir' - папка с файлами книги
    $dir = ($g | select-Object -ExpandProperty 'Group' | Select-Object -First 1 | Select-Object -ExpandProperty 'Directory').ToString()
    
    if ($dir -eq $me.Directory.ToString()) { $dir = '.' } else { $dir = $dir | Split-Path -Leaf }
    
    # поле 'BookSize' - общий размер файлов книги
    $size = $g | select-Object -ExpandProperty 'Group' | Select-Object -ExpandProperty 'Length' | Measure-Object -Sum | Select-Object -ExpandProperty 'Sum'
    
    # книга - основные поля
    $book = [PSCustomObject]@{
        'Book'      = $g.Name
        'BookSize'  = $size  # '{0, 13}' -f ('{0:n0}' -f $size)
        'BookDir'   = $dir
    }
    
    # добавляем все расширения файлов в качестве полей книги
    $ext | ForEach-Object {
        $book | Add-Member -Force -MemberType 'NoteProperty' -Name $_ -Value ''
    }
    
    # отмечаем '⬤' расширения, присутствующие среди файлов книги
    $g |
        Select-Object -ExpandProperty 'Group' |
        ForEach-Object {
            $f = $_
            $book | Add-Member -Force -MemberType 'NoteProperty' -Name $f.Extension -Value '⬤'
        }
    
    # классифицируем все файлы по (не)возможности их чтения на Kindle/iPad/...
    # есть mobi - отлично! можно сразу грузить и читать на Kindle
    if ($book.'.mobi')                                                      { $book | Add-Member -Force -MemberType 'NoteProperty' -Name 'TODO' -Value '1 - Kindle' }
    
    # mobi нет, но есть epub - конвертируем и потом грузим на Kindle
    elseif (-not $book.'.mobi' -and $book.'.epub')                          { $book | Add-Member -Force -MemberType 'NoteProperty' -Name 'TODO' -Value '2 - Kindle' }
    
    # есть только pdf - это на iPad
    elseif (-not $book.'.mobi' -and -not $book.'.epub' -and $book.'.pdf')   { $book | Add-Member -Force -MemberType 'NoteProperty' -Name 'TODO' -Value '3 - iPad' }
    
    # может это аудиокнига или что-то ещё
    else                                                                    { $book | Add-Member -Force -MemberType 'NoteProperty' -Name 'TODO' -Value '0 - nothing' }
    
    # добавляем книгу в список
    $null = $lst.Add($book)
}

# пустая строка для вставки между группами
$empty = '' | Select-Object -Property ($lst | Select-Object -First 1 | Get-Member -MemberType 'NoteProperty' | ForEach-Object { $_.Name })

# скрипт-блок экспорта в CSV
$export = {
    Param($SingleObj)
    
    $SingleObj |
    Select-Object -Property (($ext | ForEach-Object {"$_"}) + 'TODO' + 'BookSize' + 'Book' + 'BookDir') |
    Sort-Object -Property 'TODO', 'BookSize', 'Book' |
    Export-Csv -Append -NoTypeInformation -Path (Join-Path -Path $me.Directory -ChildPath ('{0}.csv' -f $me.BaseName))
}

# очищаем CSV файл
New-Item -Force -Path (Join-Path -Path $me.Directory -ChildPath ('{0}.csv' -f $me.BaseName))

# экспорт 1й пустой строки
Invoke-Command -ScriptBlock $export -ArgumentList $empty

# выгружаем список книг в CSV, сортируя по (не)возможности их чтения на Kindle/iPad и отделяя эти группы пустыми строками
$lst | Group-Object -Property 'TODO' | ForEach-Object {
    $_ | Select-Object -ExpandProperty 'Group' | ForEach-Object {
        Invoke-Command -ScriptBlock $export -ArgumentList $_
    }
    
    Invoke-Command -ScriptBlock $export -ArgumentList $empty
}
