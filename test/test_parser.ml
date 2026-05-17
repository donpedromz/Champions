open Champions.Types
open Champions.Parser

(* ============================================================
   test_parser.ml — Tests unitarios del parser
   ============================================================ *)

(* ── Utilidades de comparación ── *)

let pass label = Printf.printf "  PASS: %s\n" label
let fail label = Printf.printf "  FAIL: %s\n" label

let check_stmt label expected actual =
  if expected = actual then pass label else fail label

let check_parse_error label tokens =
  match parse tokens with
  | exception ParseError _ -> pass ("error esperado: " ^ label)
  | _ -> fail ("debía lanzar ParseError: " ^ label)

(* ── Tests de expresiones (dentro de sentencias) ── *)

let test_precedencia_aritmetica () =
  print_endline "[ precedencia aritmética ]";
  (* pasar_balon x a 2 cabeceo 3 chilena 4!  =>  x = 2 + (3 * 4) *)
  let tokens = [
    KW_LET; IDENT "x"; OP_ASSIGN;
    INT_LIT 2; OP_ADD; INT_LIT 3; OP_MUL; INT_LIT 4;
    SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Decl ("x", BinOp (Add, IntLit 2, BinOp (Mul, IntLit 3, IntLit 4)))] ->
    pass "2 + (3 * 4)"
  | _ -> fail "2 + (3 * 4)"

let test_asociatividad_izquierda () =
  print_endline "[ asociatividad izquierda ]";
  (* x a 10 rabona 3 rabona 2!  =>  x = (10 - 3) - 2 *)
  let tokens = [
    IDENT "x"; OP_ASSIGN;
    INT_LIT 10; OP_SUB; INT_LIT 3; OP_SUB; INT_LIT 2;
    SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Assign ("x", BinOp (Sub, BinOp (Sub, IntLit 10, IntLit 3), IntLit 2))] ->
    pass "(10 - 3) - 2"
  | _ -> fail "(10 - 3) - 2"

let test_concatenacion () =
  print_endline "[ concatenación de strings ]";
  (* pasar_balon s a "hola" mbappe "mundo"! *)
  let tokens = [
    KW_LET; IDENT "s"; OP_ASSIGN;
    STR_LIT "hola"; OP_CONCAT; STR_LIT "mundo";
    SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Decl ("s", BinOp (Concat, StrLit "hola", StrLit "mundo"))] ->
    pass "concatenación"
  | _ -> fail "concatenación"

let test_comparacion () =
  print_endline "[ operadores relacionales ]";
  (* gritar_gol(x transfermarkt y)! *)
  let tokens = [
    KW_PRINT; LPAREN; IDENT "x"; OP_EQ; IDENT "y"; RPAREN; SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Print (BinOp (Eq, Var "x", Var "y"))] ->
    pass "igualdad"
  | _ -> fail "igualdad"

let test_logica_and_or () =
  print_endline "[ lógica AND / OR ]";
  (* pasar_balon b a gol pase autogol sombrero gol! *)
  let tokens = [
    KW_LET; IDENT "b"; OP_ASSIGN;
    BOOL_LIT true; OP_AND; BOOL_LIT false;
    OP_OR; BOOL_LIT true;
    SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Decl ("b", BinOp (Or, BinOp (And, BoolLit true, BoolLit false), BoolLit true))] ->
    pass "and/or"
  | _ -> fail "and/or"

(* ── Tests de sentencias ── *)

let test_declaracion () =
  print_endline "[ declaración pasar_balon ]";
  let tokens = [
    KW_LET; IDENT "x"; OP_ASSIGN; INT_LIT 100; SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Decl ("x", IntLit 100)] -> pass "declaración"
  | _ -> fail "declaración"

let test_asignacion () =
  print_endline "[ asignación simple ]";
  let tokens = [
    IDENT "x"; OP_ASSIGN; INT_LIT 42; SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Assign ("x", IntLit 42)] -> pass "asignación"
  | _ -> fail "asignación"

let test_asignacion_compuesta () =
  print_endline "[ asignación compuesta tikitaka ]";
  let tokens = [
    IDENT "c"; OP_ADD_ASSIGN; INT_LIT 1; SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [CompoundAssign ("c", Add, IntLit 1)] -> pass "tikitaka"
  | _ -> fail "tikitaka"

let test_incremento () =
  print_endline "[ incremento / decremento ]";
  let tokens1 = [IDENT "i"; KW_INC; SEMICOLON; EOF] in
  let tokens2 = [IDENT "j"; KW_DEC; SEMICOLON; EOF] in
  check_stmt "ofensiva" [IncDec ("i", `Inc)] (parse tokens1);
  check_stmt "defensiva" [IncDec ("j", `Dec)] (parse tokens2)

let test_print () =
  print_endline "[ gritar_gol ]";
  let tokens = [
    KW_PRINT; LPAREN; STR_LIT "gol"; RPAREN; SEMICOLON; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Print (StrLit "gol")] -> pass "print"
  | _ -> fail "print"

let test_bloque () =
  print_endline "[ bloque { ... } ]";
  let tokens = [
    LBRACE; IDENT "x"; OP_ASSIGN; INT_LIT 1; SEMICOLON; RBRACE; EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [Block [Assign ("x", IntLit 1)]] -> pass "bloque"
  | _ -> fail "bloque"

let test_bloque_vacio () =
  print_endline "[ bloque vacío ]";
  let tokens = [LBRACE; RBRACE; EOF] in
  let ast = parse tokens in
  match ast with
  | [Block []] -> pass "bloque vacío"
  | _ -> fail "bloque vacío"

(* ── Tests de control de flujo ── *)

let test_if_simple () =
  print_endline "[ if simple ]";
  let tokens = [
    KW_IF; LPAREN; IDENT "x"; OP_GT; INT_LIT 5; RPAREN;
    LBRACE; IDENT "y"; OP_ASSIGN; INT_LIT 1; SEMICOLON; RBRACE;
    EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [If ((BinOp (Gt, Var "x", IntLit 5), [Assign ("y", IntLit 1)]), [], None)] ->
    pass "if simple"
  | _ -> fail "if simple"

let test_if_elif_else () =
  print_endline "[ if / elif / else ]";
  let tokens = [
    KW_IF; LPAREN; IDENT "a"; RPAREN;
    LBRACE; IDENT "x"; OP_ASSIGN; INT_LIT 1; SEMICOLON; RBRACE;
    KW_ELSE_IF; LPAREN; IDENT "b"; RPAREN;
    LBRACE; IDENT "x"; OP_ASSIGN; INT_LIT 2; SEMICOLON; RBRACE;
    KW_ELSE;
    LBRACE; IDENT "x"; OP_ASSIGN; INT_LIT 3; SEMICOLON; RBRACE;
    EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [If ((Var "a", [Assign ("x", IntLit 1)]),
         [(Var "b", [Assign ("x", IntLit 2)])],
         Some [Assign ("x", IntLit 3)])] ->
    pass "if/elif/else"
  | _ -> fail "if/elif/else"

let test_while_simple () =
  print_endline "[ while simple ]";
  let tokens = [
    KW_WHILE; LPAREN; IDENT "i"; OP_LT; INT_LIT 5; RPAREN;
    LBRACE; IDENT "i"; KW_INC; SEMICOLON; RBRACE;
    EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [While (None, BinOp (Lt, Var "i", IntLit 5), [IncDec ("i", `Inc)])] ->
    pass "while simple"
  | _ -> fail "while simple"

let test_while_con_init () =
  print_endline "[ while con init dual ]";
  let tokens = [
    KW_WHILE; LPAREN;
    KW_LET; IDENT "i"; OP_ASSIGN; INT_LIT 0; SEMICOLON;
    IDENT "i"; OP_LT; INT_LIT 3; RPAREN;
    LBRACE; IDENT "i"; KW_INC; SEMICOLON; RBRACE;
    EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [While (Some (Decl ("i", IntLit 0)),
            BinOp (Lt, Var "i", IntLit 3),
            [IncDec ("i", `Inc)])] ->
    pass "while con init"
  | _ -> fail "while con init"

let test_for () =
  print_endline "[ for ]";
  let tokens = [
    KW_FOR; LPAREN;
    KW_LET; IDENT "j"; OP_ASSIGN; INT_LIT 0; SEMICOLON;
    IDENT "j"; OP_LT; INT_LIT 3; SEMICOLON;
    IDENT "j"; KW_INC;
    RPAREN;
    LBRACE; IDENT "j"; KW_INC; SEMICOLON; RBRACE;
    EOF
  ] in
  let ast = parse tokens in
  match ast with
  | [For (Decl ("j", IntLit 0),
          BinOp (Lt, Var "j", IntLit 3),
          IncDec ("j", `Inc),
          [IncDec ("j", `Inc)])] ->
    pass "for"
  | _ -> fail "for"

(* ── Tests de errores ── *)

let test_error_expresion_inesperada () =
  print_endline "[ error: expresión inesperada ]";
  check_parse_error "SEMICOLON como expr" [OP_ADD; INT_LIT 1; EOF]

let test_error_sentencia_inesperada () =
  print_endline "[ error: sentencia inesperada ]";
  check_parse_error "OP_ADD como stmt" [OP_ADD; INT_LIT 1; SEMICOLON; EOF]

(* ── Runner ── *)

let () =
  print_endline "=== Tests del Parser ===";
  test_precedencia_aritmetica ();
  test_asociatividad_izquierda ();
  test_concatenacion ();
  test_comparacion ();
  test_logica_and_or ();
  test_declaracion ();
  test_asignacion ();
  test_asignacion_compuesta ();
  test_incremento ();
  test_print ();
  test_bloque ();
  test_bloque_vacio ();
  test_if_simple ();
  test_if_elif_else ();
  test_while_simple ();
  test_while_con_init ();
  test_for ();
  test_error_expresion_inesperada ();
  test_error_sentencia_inesperada ();
  print_endline "=== Fin ==="
