type token =
  | INT of (int)
  | FLOAT of (float)
  | IDENTIFIER of (string)
  | STRING of (string)
  | LPAR
  | RPAR
  | LBRACE
  | RBRACE
  | COLON
  | SEMI
  | EQUAL
  | COMMAND
  | EOF

open Parsing;;
let _ = parse_error;;
# 2 "src/redl_parser.mly"

  open Redl_ast

  let node value =
    {
      value;
      loc = Parsing.symbol_start_pos (), Parsing.symbol_end_pos ();
    }

# 29 "src/redl_parser.ml"
let yytransl_const = [|
  261 (* LPAR *);
  262 (* RPAR *);
  263 (* LBRACE *);
  264 (* RBRACE *);
  265 (* COLON *);
  266 (* SEMI *);
  267 (* EQUAL *);
  268 (* COMMAND *);
    0 (* EOF *);
    0|]

let yytransl_block = [|
  257 (* INT *);
  258 (* FLOAT *);
  259 (* IDENTIFIER *);
  260 (* STRING *);
    0|]

let yylhs = "\255\255\
\001\000\001\000\001\000\002\000\003\000\003\000\004\000\004\000\
\004\000\005\000\005\000\006\000\006\000\007\000\007\000\007\000\
\007\000\007\000\000\000"

let yylen = "\002\000\
\006\000\002\000\001\000\001\000\006\000\000\000\004\000\003\000\
\003\000\002\000\001\000\002\000\000\000\001\000\001\000\001\000\
\001\000\004\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\004\000\000\000\000\000\000\000\003\000\019\000\
\000\000\000\000\000\000\000\000\000\000\000\000\014\000\015\000\
\017\000\016\000\000\000\000\000\000\000\002\000\010\000\008\000\
\000\000\000\000\000\000\000\000\009\000\012\000\007\000\000\000\
\000\000\000\000\000\000\000\000\018\000\000\000\001\000\000\000\
\005\000"

let yydgoto = "\002\000\
\008\000\009\000\027\000\010\000\012\000\020\000\021\000"

let yysindex = "\018\000\
\001\000\000\000\000\000\001\255\014\255\019\255\000\000\000\000\
\012\255\001\000\001\255\016\255\001\255\020\255\000\000\000\000\
\000\000\000\000\012\255\017\255\012\255\000\000\000\000\000\000\
\018\255\019\255\022\255\012\255\000\000\000\000\000\000\021\255\
\001\255\025\255\019\255\001\000\000\000\028\255\000\000\020\255\
\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\026\255\000\000\027\255\000\000\000\000\029\255\000\000\000\000\
\000\000\000\000\000\000\000\000\000\255\000\000\000\000\000\000\
\000\000\000\000\000\000\031\255\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\029\255\
\000\000"

let yygindex = "\000\000\
\248\255\253\255\254\255\252\255\007\000\240\255\020\000"

let yytablesize = 269
let yytable = "\011\000\
\007\000\022\000\014\000\003\000\030\000\013\000\011\000\004\000\
\011\000\013\000\005\000\034\000\015\000\016\000\017\000\018\000\
\019\000\023\000\001\000\025\000\013\000\003\000\032\000\024\000\
\026\000\031\000\029\000\039\000\036\000\035\000\037\000\038\000\
\033\000\040\000\011\000\013\000\013\000\041\000\028\000\006\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\003\000\000\000\000\000\000\000\004\000\
\000\000\000\000\005\000\000\000\006\000"

let yycheck = "\004\000\
\000\000\010\000\006\000\003\001\021\000\006\001\011\000\007\001\
\013\000\010\001\010\001\028\000\001\001\002\001\003\001\004\001\
\005\001\011\000\001\000\013\000\007\001\003\001\026\000\008\001\
\005\001\008\001\010\001\036\000\033\000\009\001\006\001\035\000\
\011\001\006\001\008\001\010\001\006\001\040\000\019\000\011\001\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\003\001\255\255\255\255\255\255\007\001\
\255\255\255\255\010\001\255\255\012\001"

let yynames_const = "\
  LPAR\000\
  RPAR\000\
  LBRACE\000\
  RBRACE\000\
  COLON\000\
  SEMI\000\
  EQUAL\000\
  COMMAND\000\
  EOF\000\
  "

let yynames_block = "\
  INT\000\
  FLOAT\000\
  IDENTIFIER\000\
  STRING\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 4 : 'identifier) in
    let _3 = (Parsing.peek_val __caml_parser_env 3 : 'parameters) in
    let _5 = (Parsing.peek_val __caml_parser_env 1 : 'statement) in
    let _6 = (Parsing.peek_val __caml_parser_env 0 : Redl_ast.file) in
    Obj.repr(
# 26 "src/redl_parser.mly"
  ( Command_definition (node { name = _2; parameters = _3; body = _5 }) :: _6 )
# 191 "src/redl_parser.ml"
               : Redl_ast.file))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'statement) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : Redl_ast.file) in
    Obj.repr(
# 28 "src/redl_parser.mly"
  ( Statement _1 :: _2 )
# 199 "src/redl_parser.ml"
               : Redl_ast.file))
; (fun __caml_parser_env ->
    Obj.repr(
# 30 "src/redl_parser.mly"
  ( [] )
# 205 "src/redl_parser.ml"
               : Redl_ast.file))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 34 "src/redl_parser.mly"
  ( node _1 )
# 212 "src/redl_parser.ml"
               : 'identifier))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 4 : 'identifier) in
    let _4 = (Parsing.peek_val __caml_parser_env 2 : 'identifier) in
    let _6 = (Parsing.peek_val __caml_parser_env 0 : 'parameters) in
    Obj.repr(
# 38 "src/redl_parser.mly"
  ( (_2, _4) :: _6 )
# 221 "src/redl_parser.ml"
               : 'parameters))
; (fun __caml_parser_env ->
    Obj.repr(
# 40 "src/redl_parser.mly"
  ( [] )
# 227 "src/redl_parser.ml"
               : 'parameters))
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 1 : 'statements) in
    Obj.repr(
# 44 "src/redl_parser.mly"
  ( _3 )
# 234 "src/redl_parser.ml"
               : 'statement))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'statements) in
    Obj.repr(
# 46 "src/redl_parser.mly"
  ( _2 )
# 241 "src/redl_parser.ml"
               : 'statement))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'identifier) in
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'arguments) in
    Obj.repr(
# 48 "src/redl_parser.mly"
  ( node (Command (_1, _2)) )
# 249 "src/redl_parser.ml"
               : 'statement))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'statement) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'statements) in
    Obj.repr(
# 52 "src/redl_parser.mly"
  ( node (Sequence (_1, _2)) )
# 257 "src/redl_parser.ml"
               : 'statements))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'statement) in
    Obj.repr(
# 54 "src/redl_parser.mly"
  ( _1 )
# 264 "src/redl_parser.ml"
               : 'statements))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'simple_expression) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'arguments) in
    Obj.repr(
# 58 "src/redl_parser.mly"
  ( _1 :: _2 )
# 272 "src/redl_parser.ml"
               : 'arguments))
; (fun __caml_parser_env ->
    Obj.repr(
# 60 "src/redl_parser.mly"
  ( [] )
# 278 "src/redl_parser.ml"
               : 'arguments))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : int) in
    Obj.repr(
# 64 "src/redl_parser.mly"
  ( node (Int _1) )
# 285 "src/redl_parser.ml"
               : 'simple_expression))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : float) in
    Obj.repr(
# 66 "src/redl_parser.mly"
  ( node (Float _1) )
# 292 "src/redl_parser.ml"
               : 'simple_expression))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 68 "src/redl_parser.mly"
  ( node (String _1) )
# 299 "src/redl_parser.ml"
               : 'simple_expression))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 70 "src/redl_parser.mly"
  ( node (Variable _1) )
# 306 "src/redl_parser.ml"
               : 'simple_expression))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : 'simple_expression) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : 'arguments) in
    Obj.repr(
# 72 "src/redl_parser.mly"
  ( node (Apply (_2, _3)) )
# 314 "src/redl_parser.ml"
               : 'simple_expression))
(* Entry file *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let file (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Redl_ast.file)
