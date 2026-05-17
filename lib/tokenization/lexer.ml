open Types

(* Excepción para errores léxicos con posición *)
exception LexError of string

(* ── Tabla de palabras reservadas ── *)
let keywords = [
  ("pasar_balon",     KW_LET);
  ("a",               OP_ASSIGN);
  ("gritar_gol",      KW_PRINT);
  ("ataca_cr7",       KW_IF);
  ("defiende_cr7",    KW_ELSE_IF);
  ("amaga_cr7",       KW_ELSE);
  ("ataca_el_arsenal", KW_FOR);
  ("ataca_el_atleti", KW_WHILE);
  ("saque",           KW_RETURN);
  ("ofensiva",        KW_INC);
  ("defensiva",       KW_DEC);
  ("gol",             BOOL_LIT true);
  ("autogol",         BOOL_LIT false);
  ("cabeceo",         OP_ADD);
  ("rabona",          OP_SUB);
  ("chilena",         OP_MUL);
  ("penalti",         OP_DIV);
  ("volea",           OP_MOD);
  ("mbappe",          OP_CONCAT);
  ("tikitaka",        OP_ADD_ASSIGN);
  ("mudryk",          OP_SUB_ASSIGN);
  ("transfermarkt",   OP_EQ);
  ("vendehumo",       OP_NEQ);
  ("barredora",       OP_GT);
  ("amarilla",        OP_GEQ);
  ("roja",            OP_LT);
  ("zancadilla",      OP_LEQ);
  ("pase",            OP_AND);
  ("sombrero",        OP_OR);
  ("centro",          COMMA);
]

(* ── Función principal: convierte texto en lista de tokens ── *)
let tokenize input =
  let pos  = ref 0 in
  let line = ref 1 in
  let col  = ref 1 in
  let len  = String.length input in

  let lex_error msg =
    raise (LexError (Printf.sprintf "Error léxico en línea %d, columna %d: %s" !line !col msg))
  in

  let peek () =
    if !pos < len then Some input.[!pos] else None
  in

  let advance () =
    if !pos < len then begin
      if input.[!pos] = '\n' then (incr line; col := 1)
      else incr col;
      incr pos
    end
  in

  let is_digit c = c >= '0' && c <= '9' in
  let is_alpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c = '_' in
  let is_alnum c = is_alpha c || is_digit c in

  (* Saltea espacios en blanco y comentarios # ... \n *)
  let skip () =
    let running = ref true in
    while !running do
      match peek () with
      | Some (' ' | '\t' | '\r' | '\n') -> advance ()
      | Some '#' ->
        while (match peek () with Some '\n' | None -> false | _ -> true) do
          advance ()
        done
      | _ -> running := false
    done
  in

  (* Lee dígitos consecutivos y devuelve el entero *)
  let read_int () =
    let start = !pos in
    while (match peek () with Some c when is_digit c -> true | _ -> false) do
      advance ()
    done;
    int_of_string (String.sub input start (!pos - start))
  in

  (* Lee el contenido de un literal de cadena (sin las comillas) *)
  let read_string () =
    advance ();  (* saltar comilla inicial *)
    let buf = Buffer.create 32 in
    let rec loop () =
      match peek () with
      | None     -> lex_error "string sin cerrar (fin de archivo inesperado)"
      | Some '"' -> advance ()  (* saltar comilla final *)
      | Some '\\' ->
        advance ();
        (match peek () with
         | Some 'n'  -> Buffer.add_char buf '\n'; advance ()
         | Some 't'  -> Buffer.add_char buf '\t'; advance ()
         | Some '"'  -> Buffer.add_char buf '"';  advance ()
         | Some '\\' -> Buffer.add_char buf '\\'; advance ()
         | Some c    -> Buffer.add_char buf '\\'; Buffer.add_char buf c; advance ()
         | None      -> lex_error "secuencia de escape incompleta");
        loop ()
      | Some c -> Buffer.add_char buf c; advance (); loop ()
    in
    loop ();
    Buffer.contents buf
  in

  (* Lee una palabra completa (letras, dígitos, guión bajo) *)
  let read_word () =
    let start = !pos in
    while (match peek () with Some c when is_alnum c -> true | _ -> false) do
      advance ()
    done;
    String.sub input start (!pos - start)
  in

  (* Loop principal *)
  let result = ref [] in
  let rec lex () =
    skip ();
    match peek () with
    | None ->
      result := EOF :: !result
    | Some c ->
      let tok = match c with
        | '(' -> advance (); LPAREN
        | ')' -> advance (); RPAREN
        | '{' -> advance (); LBRACE
        | '}' -> advance (); RBRACE
        | '!' -> advance (); SEMICOLON
        | '"' -> STR_LIT (read_string ())
        | c when is_digit c -> INT_LIT (read_int ())
        | c when is_alpha c ->
          let word = read_word () in
          (match List.assoc_opt word keywords with
           | Some t -> t
           | None   -> IDENT word)
        | c ->
          lex_error (Printf.sprintf "carácter '%c' no reconocido" c)
      in
      result := tok :: !result;
      lex ()
  in
  lex ();
  List.rev !result

(* ── Convierte un token a string legible (modo --tokens) ── *)
let string_of_token = function
  | KW_LET          -> "KW_LET(pasar_balon)"
  | KW_PRINT        -> "KW_PRINT(gritar_gol)"
  | KW_IF           -> "KW_IF(ataca_cr7)"
  | KW_ELSE_IF      -> "KW_ELSE_IF(defiende_cr7)"
  | KW_ELSE         -> "KW_ELSE(amaga_cr7)"
  | KW_FOR          -> "KW_FOR(ataca_el_arsenal)"
  | KW_WHILE        -> "KW_WHILE(ataca_el_atleti)"
  | KW_INC          -> "KW_INC(ofensiva)"
  | KW_DEC          -> "KW_DEC(defensiva)"
  | KW_RETURN       -> "KW_RETURN(saque)"
  | OP_ASSIGN       -> "OP_ASSIGN(a)"
  | OP_ADD          -> "OP_ADD(cabeceo)"
  | OP_SUB          -> "OP_SUB(rabona)"
  | OP_MUL          -> "OP_MUL(chilena)"
  | OP_DIV          -> "OP_DIV(penalti)"
  | OP_MOD          -> "OP_MOD(volea)"
  | OP_CONCAT       -> "OP_CONCAT(mbappe)"
  | OP_ADD_ASSIGN   -> "OP_ADD_ASSIGN(tikitaka)"
  | OP_SUB_ASSIGN   -> "OP_SUB_ASSIGN(mudryk)"
  | OP_EQ           -> "OP_EQ(transfermarkt)"
  | OP_NEQ          -> "OP_NEQ(vendehumo)"
  | OP_GT           -> "OP_GT(barredora)"
  | OP_GEQ          -> "OP_GEQ(amarilla)"
  | OP_LT           -> "OP_LT(roja)"
  | OP_LEQ          -> "OP_LEQ(zancadilla)"
  | OP_AND          -> "OP_AND(pase)"
  | OP_OR           -> "OP_OR(sombrero)"
  | LPAREN          -> "LPAREN"
  | RPAREN          -> "RPAREN"
  | LBRACE          -> "LBRACE"
  | RBRACE          -> "RBRACE"
  | COMMA           -> "COMMA(centro)"
  | SEMICOLON       -> "SEMICOLON(!)"
  | INT_LIT  n      -> Printf.sprintf "INT_LIT(%d)" n
  | STR_LIT  s      -> Printf.sprintf "STR_LIT(%S)" s
  | BOOL_LIT b      -> Printf.sprintf "BOOL_LIT(%b)" b
  | IDENT    s      -> Printf.sprintf "IDENT(%s)" s
  | EOF             -> "EOF"
