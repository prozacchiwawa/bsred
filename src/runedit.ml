open Key
open Text

let test_edit = Main.edit "hi.txt" "(* Hi there *)\nlet x = 3"
let keys = [
  Down ;
  Down ;
  End ;
  Return ;
  Letter_l ;
  Letter_e ;
  Letter_t ;
  Space ;
  Letter_y ;
  Space ;
  Equal ;
  Space ;
  Digit_5 ;
  Return ;
  Ctrl_s
  ]

let _ = List.iter (State.on_key_press test_edit) keys
let _ = List.iter (fun (f : File.t) -> print_endline (Text.to_string f.text)) test_edit.files

