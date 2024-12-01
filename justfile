run num:
    gleam run -m day01/day{{num}}

new num:
    mkdir src/day{{num}}
    cp templates/template.gleam src/day{{num}}/day{{num}}.gleam
