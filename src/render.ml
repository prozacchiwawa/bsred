open Term
open Style

module Int = struct
  type t = int
  let compare a b = Pervasives.compare a b
end
module IntSet = Set.Make(Int)

type style = Style.t

type cell =
  { cellStyle : Style.t
  ; cellChar : Character.t
  }
type textmsg =
  { value : string
  ; msgX : int
  ; msgY : int
  ; msgWidth : int
  ; style : Style.t
  }

type event =
  | SetChar of (int * int * cell)
  | TextMsg of textmsg

type frame =
  { styles : Style.t array
  ; chars : Character.t array
  ; diffs : IntSet.t ref
  ; planeWidth : int
  ; planeHeight : int
  ; texts : textmsg list ref
  }

let cell ~style:style ch = { cellStyle = style ; cellChar = ch }
let set frame x y cell =
  let idx = ((y * frame.planeWidth) + x) in
  let prevStyle = Array.get frame.styles idx in
  let prevChar = Array.get frame.chars idx in
  if prevStyle <> cell.cellStyle || prevChar <> cell.cellChar then
    let _ = Array.set frame.styles idx cell.cellStyle in
    let _ = Array.set frame.chars idx cell.cellChar in
    let _ = frame.diffs := IntSet.add idx !(frame.diffs) in
    ()
let text ?(style = Style.default) frame x y w str =
  let l = String.length str in
  for i = 0 to min (x + (w - 1)) (frame.planeWidth - x - 1) do
    let ch =
      if i < l then
        String.sub str i 1
      else
        " "
    in
    set frame (x + i) y { cellStyle = style ; cellChar = ch }
  done ;
  frame.texts := { value = str ; msgX = x ; msgY = y ; msgWidth = w ; style = style } :: !(frame.texts)

let width frame = frame.planeWidth
let height frame = frame.planeHeight
let new_frame x y =
  { styles = Array.make (x * y) Style.default
  ; chars = Array.make (x * y) (Character.of_ascii ' ')
  ; diffs = ref IntSet.empty
  ; planeWidth = max 1 x
  ; planeHeight = max 1 y
  ; texts = ref []
  }
let render frame =
  let diffs = IntSet.elements !(frame.diffs) in
  let _ = frame.diffs := IntSet.empty in
  List.concat
    [ diffs
      |> List.map
        (fun idx ->
           let x = idx mod frame.planeWidth in
           let y = idx / frame.planeWidth in
           SetChar (x, y, { cellStyle = Array.get frame.styles idx ; cellChar = Array.get frame.chars idx })
        )
    ; !(frame.texts)
      |> List.rev
      |> List.map (fun t -> TextMsg t)
    ]
  |> Array.of_list
