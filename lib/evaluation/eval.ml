open Types

(* ============================================================
   eval.ml — Evaluador del lenguaje Champions

   Entrada:  stmt list  (AST producido por parser.ml)
   Salida:   efectos de lado (impresión) + entorno final

   El entorno es un StringMap inmutable. Cada bloque recibe el
   entorno del padre, lo extiende localmente y al salir descarta
   las variables nuevas (scoping léxico de bloques).
   ============================================================ *)

exception RuntimeError of string

(* ── Utilidades de valor ── *)

let string_of_value = function
  | VInt n    -> string_of_int n
  | VString s -> s
  | VBool b   -> if b then "gol" else "autogol"

(* ── Entorno ── *)

let lookup env name =
  match StringMap.find_opt name env with
  | Some v -> v
  | None   -> raise (RuntimeError (
      Printf.sprintf "Variable '%s' no definida" name))

(* Salida de scope: devuelve base con los valores actualizados de inner.
   Variables declaradas en inner pero no en base son descartadas. *)
let exit_scope base inner =
  StringMap.merge (fun _k base_opt inner_opt ->
    match base_opt, inner_opt with
    | None,   _        -> None         (* nueva en inner: descartar *)
    | Some v, None     -> Some v       (* en base pero no inner: mantener base *)
    | Some _, Some v   -> Some v       (* en ambas: tomar valor actualizado *)
  ) base inner

(* ── Operadores binarios ── *)

let eval_binop op left right =
  let op_name = match op with
    | Add -> "cabeceo" | Sub -> "rabona"  | Mul -> "chilena"
    | Div -> "penalti" | Mod -> "volea"   | Concat -> "mbappe"
    | Eq  -> "transfermarkt" | Neq -> "vendehumo"
    | Lt  -> "roja"    | Gt  -> "barredora"
    | Leq -> "zancadilla"    | Geq -> "amarilla"
    | And -> "pase"    | Or  -> "sombrero"
  in
  match op, left, right with
  (* Aritmética entera *)
  | Add, VInt a, VInt b -> VInt (a + b)
  | Sub, VInt a, VInt b -> VInt (a - b)
  | Mul, VInt a, VInt b -> VInt (a * b)
  | Div, VInt a, VInt b ->
    if b = 0 then raise (RuntimeError "División entre cero (penalti con divisor 0)")
    else VInt (a / b)
  | Mod, VInt a, VInt b ->
    if b = 0 then raise (RuntimeError "Módulo entre cero (volea con divisor 0)")
    else VInt (a mod b)
  (* Concatenación: string × (string | int) o int × string *)
  | Concat, VString a, VString b -> VString (a ^ b)
  | Concat, VString a, VInt b    -> VString (a ^ string_of_int b)
  | Concat, VInt a,    VString b -> VString (string_of_int a ^ b)
  (* Comparación de orden: solo enteros *)
  | Lt,  VInt a, VInt b -> VBool (a <  b)
  | Gt,  VInt a, VInt b -> VBool (a >  b)
  | Leq, VInt a, VInt b -> VBool (a <= b)
  | Geq, VInt a, VInt b -> VBool (a >= b)
  (* Igualdad: int, string o bool *)
  | Eq,  VInt a,    VInt b    -> VBool (a =  b)
  | Eq,  VString a, VString b -> VBool (a =  b)
  | Eq,  VBool a,   VBool b   -> VBool (a =  b)
  | Neq, VInt a,    VInt b    -> VBool (a <> b)
  | Neq, VString a, VString b -> VBool (a <> b)
  | Neq, VBool a,   VBool b   -> VBool (a <> b)
  (* Lógica booleana *)
  | And, VBool a, VBool b -> VBool (a && b)
  | Or,  VBool a, VBool b -> VBool (a || b)
  (* Tipos incompatibles *)
  | _ ->
    raise (RuntimeError (Printf.sprintf
      "Tipos incompatibles: '%s' %s '%s'"
      (string_of_value left) op_name (string_of_value right)))

(* ── Evaluador de expresiones ── *)

let rec eval_expr env = function
  | IntLit  n -> VInt n
  | StrLit  s -> VString s
  | BoolLit b -> VBool b
  | Var name  -> lookup env name
  | BinOp (op, l, r) ->
    let lv = eval_expr env l in
    let rv = eval_expr env r in
    eval_binop op lv rv
  | Call _ ->
    raise (RuntimeError "Llamadas a funciones son de Fase 2 (no implementado aún)")

(* ── Evaluador de sentencias ── *)

(* eval_stmt: ejecuta una sentencia y retorna el entorno actualizado *)
let rec eval_stmt env = function

  | Decl (name, expr) ->
    StringMap.add name (eval_expr env expr) env

  | Assign (name, expr) ->
    if not (StringMap.mem name env) then
      raise (RuntimeError (Printf.sprintf
        "Variable '%s' no declarada. Usa 'pasar_balon %s a ...' para declararla primero"
        name name));
    StringMap.add name (eval_expr env expr) env

  | CompoundAssign (name, op, expr) ->
    let cur  = lookup env name in
    let rval = eval_expr env expr in
    StringMap.add name (eval_binop op cur rval) env

  | IncDec (name, dir) ->
    (match lookup env name with
     | VInt n ->
       let v = match dir with `Inc -> n + 1 | `Dec -> n - 1 in
       StringMap.add name (VInt v) env
     | _ ->
       raise (RuntimeError (Printf.sprintf
         "'%s' no es un entero; ofensiva/defensiva solo aplican a enteros" name)))

  | Print expr ->
    print_endline (string_of_value (eval_expr env expr));
    env

  | If ((cond, then_body), elifs, else_opt) ->
    (match eval_expr env cond with
     | VBool true  -> eval_block env then_body
     | VBool false ->
       let rec try_elifs = function
         | [] ->
           (match else_opt with
            | Some body -> eval_block env body
            | None      -> env)
         | (ec, eb) :: rest ->
           (match eval_expr env ec with
            | VBool true  -> eval_block env eb
            | VBool false -> try_elifs rest
            | _ -> raise (RuntimeError
                "Condición defiende_cr7 debe ser gol o autogol"))
       in
       try_elifs elifs
     | _ ->
       raise (RuntimeError "Condición ataca_cr7 debe ser gol o autogol"))

  | While (init_opt, cond, body) ->
    (* Ejecutar init opcional (crea variable en scope local del while) *)
    let loop_env = match init_opt with
      | Some s -> eval_stmt env s
      | None   -> env
    in
    let r = ref loop_env in
    while (match eval_expr !r cond with
           | VBool b -> b
           | _ -> raise (RuntimeError
               "Condición ataca_el_atleti debe ser gol o autogol")) do
      r := eval_block !r body
    done;
    (* Variables declaradas en init_opt no escapan al scope externo *)
    exit_scope env !r

  | For (init, cond, update, body) ->
    let init_name = match init with
      | Decl (n, _) -> n
      | _ -> raise (RuntimeError
          "El inicializador de ataca_el_arsenal debe ser una declaración pasar_balon")
    in
    let loop_env = eval_stmt env init in
    let r = ref loop_env in
    while (match eval_expr !r cond with
           | VBool b -> b
           | _ -> raise (RuntimeError
               "Condición ataca_el_arsenal debe ser gol o autogol")) do
      r := eval_block !r body;
      r := eval_stmt !r update
    done;
    (* Descartar variable contadora; propagar cambios a variables externas *)
    exit_scope env (StringMap.remove init_name !r)

  | Block stmts ->
    eval_block env stmts

  | Return _ ->
    raise (RuntimeError "saque solo es válido dentro de una función (Fase 2)")

  | ExprStmt expr ->
    ignore (eval_expr env expr);
    env

(* eval_block: ejecuta una lista de sentencias en scope hijo.
   Las variables nuevas se descartan al salir; las mutaciones a
   variables del padre sí se propagan hacia afuera. *)
and eval_block env stmts =
  let inner = List.fold_left eval_stmt env stmts in
  exit_scope env inner

(* ── Punto de entrada ── *)

let run (stmts : stmt list) : unit =
  ignore (List.fold_left eval_stmt StringMap.empty stmts)
