let () =
  if Array.length Sys.argv < 2 then begin
    Printf.eprintf "Uso: champions <archivo.cr7> [--tokens]\n";
    exit 1
  end;
  let filename     = Sys.argv.(1) in
  let debug_tokens = Array.length Sys.argv >= 3 && Sys.argv.(2) = "--tokens" in
  let ic      = open_in filename in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  match Champions.Lexer.tokenize content with
  | exception Champions.Lexer.LexError msg ->
    Printf.eprintf "%s\n" msg;
    exit 1
  | tokens ->
    if debug_tokens then
      List.iter (fun t -> print_endline (Champions.Lexer.token_to_string t)) tokens
    else
      print_endline "Parser no implementado aún."
