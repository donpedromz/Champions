(* ============================================================
   main.ml — Punto de entrada del intérprete Champions

   Pipeline de fases:
   1. TOKENIZACIÓN  (Lexer.tokenize)  →  lib/tokenization/
   2. PARSEO        (Parser.parse)     →  lib/parsing/
   3. EVALUACIÓN    (Eval.run)         →  lib/evaluation/  (Persona C)
   ============================================================ *)

let read_file filename =
  let ic = open_in_bin filename in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  content

let print_usage () =
  Printf.eprintf "Uso: champions <archivo.cr7> [--tokens]\n";
  exit 1

let () =
  (* ---- Leer argumentos ---- *)
  if Array.length Sys.argv < 2 then print_usage ();
  let filename     = Sys.argv.(1) in
  let debug_tokens = Array.length Sys.argv >= 3 && Sys.argv.(2) = "--tokens" in

  (* ---- Fase 1: Tokenización ---- *)
  let source = read_file filename in
  let tokens =
    match Champions.Lexer.tokenize source with
    | exception Champions.Lexer.LexError msg ->
      Printf.eprintf "[LEXER] %s\n" msg;
      exit 1
    | tokens -> tokens
  in

  if debug_tokens then begin
    print_endline "=== Tokens ===";
    List.iter (fun t -> print_endline (Champions.Lexer.string_of_token t)) tokens;
    exit 0
  end;

  (* ---- Fase 2: Parseo ---- *)
  let _ast =
    match Champions.Parser.parse tokens with
    | exception Champions.Parser.ParseError msg ->
      Printf.eprintf "[PARSER] %s\n" msg;
      exit 1
    | ast -> ast
  in

  (* ---- Fase 3: Evaluación (pendiente — Persona C) ---- *)
  print_endline "Análisis sintáctico completado.";
  print_endline "Evaluación pendiente: implementar lib/evaluation/eval.ml";
  exit 0
