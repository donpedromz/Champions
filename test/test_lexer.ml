open Champions.Types
open Champions.Lexer

(* ── Utilidades ── *)

let check_equal label expected actual =
  if expected = actual then
    Printf.printf "  PASS: %s\n" label
  else begin
    Printf.printf "  FAIL: %s\n" label;
    Printf.printf "    Esperado: [%s]\n"
      (String.concat "; " (List.map string_of_token expected));
    Printf.printf "    Obtenido: [%s]\n"
      (String.concat "; " (List.map string_of_token actual))
  end

let check_lex_error label input =
  match tokenize input with
  | exception LexError _ -> Printf.printf "  PASS (error esperado): %s\n" label
  | _ -> Printf.printf "  FAIL (debía lanzar LexError): %s\n" label

(* ── Casos de prueba ── *)

let test_declaracion () =
  print_endline "[ declaración básica ]";
  check_equal
    "pasar_balon x a 100!"
    [KW_LET; IDENT "x"; OP_ASSIGN; INT_LIT 100; SEMICOLON; EOF]
    (tokenize "pasar_balon x a 100!")

let test_condicional () =
  print_endline "[ encabezado condicional ]";
  check_equal
    "ataca_cr7(x zancadilla 7){"
    [KW_IF; LPAREN; IDENT "x"; OP_LEQ; INT_LIT 7; RPAREN; LBRACE; EOF]
    (tokenize "ataca_cr7(x zancadilla 7){")

let test_booleanos () =
  print_endline "[ literales booleanos y operador lógico ]";
  check_equal
    "gol pase autogol"
    [BOOL_LIT true; OP_AND; BOOL_LIT false; EOF]
    (tokenize "gol pase autogol")

let test_concatenacion () =
  print_endline "[ string y concatenación ]";
  check_equal
    {|"hola" mbappe i|}
    [STR_LIT "hola"; OP_CONCAT; IDENT "i"; EOF]
    (tokenize {|"hola" mbappe i|})

let test_comentario () =
  print_endline "[ comentario omitido ]";
  check_equal
    "# esto es un comentario\npasar_balon"
    [KW_LET; EOF]
    (tokenize "# esto es un comentario\npasar_balon")

let test_operadores_aritmeticos () =
  print_endline "[ operadores aritméticos ]";
  check_equal
    "x cabeceo y chilena z"
    [IDENT "x"; OP_ADD; IDENT "y"; OP_MUL; IDENT "z"; EOF]
    (tokenize "x cabeceo y chilena z")

let test_asignacion_compuesta () =
  print_endline "[ asignación compuesta ]";
  check_equal
    "contador tikitaka 1!"
    [IDENT "contador"; OP_ADD_ASSIGN; INT_LIT 1; SEMICOLON; EOF]
    (tokenize "contador tikitaka 1!")

let test_incremento () =
  print_endline "[ incremento y decremento ]";
  check_equal
    "i ofensiva! j defensiva!"
    [IDENT "i"; KW_INC; SEMICOLON; IDENT "j"; KW_DEC; SEMICOLON; EOF]
    (tokenize "i ofensiva! j defensiva!")

let test_string_escape () =
  print_endline "[ escape en string ]";
  check_equal
    {|"hola\nmundo"|}
    [STR_LIT "hola\nmundo"; EOF]
    (tokenize {|"hola\nmundo"|})

let test_programa_completo () =
  print_endline "[ programa completo ]";
  let prog = {|
pasar_balon x a 20!
pasar_balon contador a 0!
ataca_el_atleti(contador roja 3){
  gritar_gol(contador)!
  contador tikitaka 1!
}
ataca_cr7(x barredora 5){
  gritar_gol("Mayor que 5")!
}
amaga_cr7{
  gritar_gol("Menor o igual")!
}
|} in
  let tokens = tokenize prog in
  (* Solo verificamos que no explota y termina con EOF *)
  let last = List.nth tokens (List.length tokens - 1) in
  check_equal "termina en EOF" [EOF] [last]

(* ── Pruebas de error ── *)

let test_caracter_invalido () =
  print_endline "[ error: carácter inválido ]";
  check_lex_error "signo $" "pasar_balon x a $!"

let test_string_sin_cerrar () =
  print_endline "[ error: string sin cerrar ]";
  check_lex_error "string abierto" {|gritar_gol("sin cerrar)!|}

(* ── Runner ── *)

let () =
  print_endline "=== Tests del Lexer ===";
  test_declaracion ();
  test_condicional ();
  test_booleanos ();
  test_concatenacion ();
  test_comentario ();
  test_operadores_aritmeticos ();
  test_asignacion_compuesta ();
  test_incremento ();
  test_string_escape ();
  test_programa_completo ();
  test_caracter_invalido ();
  test_string_sin_cerrar ();
  print_endline "=== Fin ==="
