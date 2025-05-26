export def 'str split' [expression: string] {
  if ($in | is-not-empty) {
    $in | split row $expression | str trim
  } else {
    []
  }
}
