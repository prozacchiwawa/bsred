open Term
open Style

type frame = Dontcare
type style = Style.t
type cell = DC1

let cell ~style:style ch = DC1
let set frame x y cell = ()
let text ~style:style frame x y w str = ()
let width frame = 80
let height frame = 24
