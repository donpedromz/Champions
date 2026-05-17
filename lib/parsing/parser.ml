open Types

(* ============================================================
   parser.ml — Analizador sintáctico del lenguaje Champions

   Entrada:  token list  (producida por lexer.ml)
   Salida:   stmt list   (AST definido en types.ml)

   Implementa un parser recursivo descendente (recursive descent).
   Cada regla BNF se convierte en una función que consume tokens
   y retorna un nodo del AST.
   ============================================================ *)

(* Excepción para errores de sintaxis *)
exception ParseError of string

(* ------ Estado del parser ------ *)
(* El parser mantiene una referencia a la lista de tokens restantes.
   consume() saca el siguiente token; peek() mira sin consumir. *)

type parser_state = {
  mutable tokens : token list;
}

let make_parser tokens = { tokens }

(* Mirar el token actual sin consumirlo *)
let peek ps =
  match ps.tokens with
  | [] -> EOF
  | t :: _ -> t

(* Consumir el token actual y avanzar *)
let advance ps =
  match ps.tokens with
  | [] -> EOF
  | t :: rest -> ps.tokens <- rest; t

(* Consumir un token esperado o lanzar error *)
let expect ps expected =
  let got = advance ps in
  if got <> expected then
    raise (ParseError (
      Printf.sprintf "Se esperaba %s pero se encontró %s"
        (Lexer.string_of_token expected)
        (Lexer.string_of_token got)))

(* Verificar si el token actual es el esperado sin consumir *)
let check ps expected =
  peek ps = expected

(* Consumir si coincide, retornar bool *)
let match_token ps expected =
  if check ps expected then (ignore (advance ps); true)
  else false


(* ============================================================
   FUNCIONES DEL PARSER — una por cada regla BNF
   ============================================================ *)

(* ------ Expresiones ------ *)
(* Precedencia (de menor a mayor):
   1. OR  (sombrero)
   2. AND (pase)
   3. Relacionales (transfermarkt, vendehumo, roja, barredora, etc.)
   4. Suma/Resta/Concatenación (cabeceo, rabona, mbappe)
   5. Mult/Div/Mod (chilena, penalti, volea)
   6. Factor (literal, variable, paréntesis)
*)

let rec parse_expr ps =
  parse_or ps

and parse_or ps =
  let left = parse_and ps in
  let rec loop acc =
    if match_token ps OP_OR then
      let right = parse_and ps in
      loop (BinOp (Or, acc, right))
    else acc
  in
  loop left

and parse_and ps =
  let left = parse_comparison ps in
  let rec loop acc =
    if match_token ps OP_AND then
      let right = parse_comparison ps in
      loop (BinOp (And, acc, right))
    else acc
  in
  loop left

and parse_comparison ps =
  let left = parse_addition ps in
  let op = match peek ps with
    | OP_EQ  -> Some Eq  | OP_NEQ -> Some Neq
    | OP_LT  -> Some Lt  | OP_GT  -> Some Gt
    | OP_LEQ -> Some Leq | OP_GEQ -> Some Geq
    | _ -> None
  in
  match op with
  | Some op ->
    ignore (advance ps);
    let right = parse_addition ps in
    BinOp (op, left, right)
  | None -> left

and parse_addition ps =
  let left = parse_multiplication ps in
  let rec loop acc =
    match peek ps with
    | OP_ADD ->
      ignore (advance ps);
      let right = parse_multiplication ps in
      loop (BinOp (Add, acc, right))
    | OP_SUB ->
      ignore (advance ps);
      let right = parse_multiplication ps in
      loop (BinOp (Sub, acc, right))
    | OP_CONCAT ->
      ignore (advance ps);
      let right = parse_multiplication ps in
      loop (BinOp (Concat, acc, right))
    | _ -> acc
  in
  loop left

and parse_multiplication ps =
  let left = parse_factor ps in
  let rec loop acc =
    match peek ps with
    | OP_MUL ->
      ignore (advance ps);
      let right = parse_factor ps in
      loop (BinOp (Mul, acc, right))
    | OP_DIV ->
      ignore (advance ps);
      let right = parse_factor ps in
      loop (BinOp (Div, acc, right))
    | OP_MOD ->
      ignore (advance ps);
      let right = parse_factor ps in
      loop (BinOp (Mod, acc, right))
    | _ -> acc
  in
  loop left

and parse_factor ps =
  match advance ps with
  | INT_LIT n   -> IntLit n
  | STR_LIT s   -> StrLit s
  | BOOL_LIT b  -> BoolLit b
  | IDENT name  -> Var name
  | LPAREN ->
    let e = parse_expr ps in
    expect ps RPAREN;
    e
  | tok ->
    raise (ParseError (
      Printf.sprintf "Expresión inesperada: %s" (Lexer.string_of_token tok)))


(* ------ Sentencias ------ *)

(* Declaración: pasar_balon <id> a <expr> !
   KW_LET ya fue consumido por el caller. *)
let parse_declaration ps =
  let name = match advance ps with
    | IDENT s -> s
    | tok -> raise (ParseError (
        Printf.sprintf "Se esperaba nombre de variable, se encontró %s"
          (Lexer.string_of_token tok)))
  in
  expect ps OP_ASSIGN;
  let value = parse_expr ps in
  expect ps SEMICOLON;
  Decl (name, value)

(* Impresión: gritar_gol ( <expr> ) !
   KW_PRINT ya fue consumido. *)
let parse_print ps =
  expect ps LPAREN;
  let e = parse_expr ps in
  expect ps RPAREN;
  expect ps SEMICOLON;
  Print e

(* Bloque: { <sentencias> }
   Retorna lista de sentencias (sin envolver en Block). *)
let rec parse_block ps =
  expect ps LBRACE;
  let stmts = parse_statements_until ps RBRACE in
  expect ps RBRACE;
  stmts

(* Condicional:
   ataca_cr7(<expr>){ ... }
   [defiende_cr7(<expr>){...}]*
   [amaga_cr7{...}] *)
and parse_if ps =
  expect ps LPAREN;
  let cond = parse_expr ps in
  expect ps RPAREN;
  let then_body = parse_block ps in
  let rec read_elifs acc =
    if match_token ps KW_ELSE_IF then begin
      expect ps LPAREN;
      let elif_cond = parse_expr ps in
      expect ps RPAREN;
      let elif_body = parse_block ps in
      read_elifs ((elif_cond, elif_body) :: acc)
    end
    else List.rev acc
  in
  let elifs = read_elifs [] in
  let else_body =
    if match_token ps KW_ELSE then
      Some (parse_block ps)
    else
      None
  in
  If ((cond, then_body), elifs, else_body)

(* While: ataca_el_atleti(<init_opt> <cond>){ ... }
   init_opt puede ser pasar_balon <id> a <expr> ! *)
and parse_while ps =
  expect ps LPAREN;
  let init_opt =
    if check ps KW_LET then Some (parse_statement ps)
    else None
  in
  let cond = parse_expr ps in
  expect ps RPAREN;
  let body = parse_block ps in
  While (init_opt, cond, body)

(* For: ataca_el_arsenal(<init>! <cond>! <update>){ ... } *)
and parse_for ps =
  expect ps LPAREN;
  expect ps KW_LET;
  let init = parse_declaration ps in
  let cond = parse_expr ps in
  expect ps SEMICOLON;
  let update = match advance ps with
    | IDENT name ->
      (match advance ps with
       | KW_INC -> IncDec (name, `Inc)
       | KW_DEC -> IncDec (name, `Dec)
       | tok -> raise (ParseError (
           Printf.sprintf "Se esperaba ofensiva/defensiva, se encontró %s"
             (Lexer.string_of_token tok))))
    | tok -> raise (ParseError (
        Printf.sprintf "Se esperaba identificador en actualización del for, se encontró %s"
          (Lexer.string_of_token tok)))
  in
  expect ps RPAREN;
  let body = parse_block ps in
  For (init, cond, update, body)

(* Dispatch: determina qué tipo de sentencia parsear *)
and parse_statement ps =
  match peek ps with
  | KW_LET     -> ignore (advance ps); parse_declaration ps
  | KW_PRINT   -> ignore (advance ps); parse_print ps
  | KW_IF      -> ignore (advance ps); parse_if ps
  | KW_WHILE   -> ignore (advance ps); parse_while ps
  | KW_FOR     -> ignore (advance ps); parse_for ps
  | LBRACE     -> Block (parse_block ps)
  | IDENT name ->
    ignore (advance ps);
    (match peek ps with
     | OP_ASSIGN ->
       ignore (advance ps);
       let e = parse_expr ps in
       expect ps SEMICOLON;
       Assign (name, e)
     | OP_ADD_ASSIGN ->
       ignore (advance ps);
       let e = parse_expr ps in
       expect ps SEMICOLON;
       CompoundAssign (name, Add, e)
     | OP_SUB_ASSIGN ->
       ignore (advance ps);
       let e = parse_expr ps in
       expect ps SEMICOLON;
       CompoundAssign (name, Sub, e)
     | KW_INC ->
       ignore (advance ps);
       expect ps SEMICOLON;
       IncDec (name, `Inc)
     | KW_DEC ->
       ignore (advance ps);
       expect ps SEMICOLON;
       IncDec (name, `Dec)
     | tok ->
       raise (ParseError (
         Printf.sprintf "Sentencia inesperada después de '%s': %s"
           name (Lexer.string_of_token tok))))
  | tok ->
    raise (ParseError (
      Printf.sprintf "Sentencia inesperada: %s" (Lexer.string_of_token tok)))

(* Parsear sentencias hasta encontrar un token de cierre *)
and parse_statements_until ps stop =
  let rec loop acc =
    if peek ps = stop || peek ps = EOF then
      List.rev acc
    else
      let s = parse_statement ps in
      loop (s :: acc)
  in
  loop []


(* ------ Punto de entrada ------ *)

let parse (tokens : token list) : stmt list =
  let ps = make_parser tokens in
  let program = parse_statements_until ps EOF in
  expect ps EOF;
  program
