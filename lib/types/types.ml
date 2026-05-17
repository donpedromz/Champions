(* Contrato compartido entre Lexer, Parser y Evaluador.
   NO modificar sin acuerdo del equipo. *)

(* ── Tokens producidos por el Lexer ── *)
type token =
  | KW_LET          (* pasar_balon *)
  | KW_PRINT        (* gritar_gol  *)
  | KW_IF           (* ataca_cr7   *)
  | KW_ELSE_IF      (* defiende_cr7 *)
  | KW_ELSE         (* amaga_cr7   *)
  | KW_FOR          (* ataca_el_arsenal *)
  | KW_WHILE        (* ataca_el_atleti  *)
  | KW_INC          (* ofensiva  ++ *)
  | KW_DEC          (* defensiva -- *)
  | KW_RETURN       (* saque        *)
  | OP_ASSIGN       (* a            *)
  | OP_ADD          (* cabeceo   +  *)
  | OP_SUB          (* rabona    -  *)
  | OP_MUL          (* chilena   *  *)
  | OP_DIV          (* penalti   /  *)
  | OP_MOD          (* volea     %  *)
  | OP_CONCAT       (* mbappe    ^  *)
  | OP_ADD_ASSIGN   (* tikitaka  += *)
  | OP_SUB_ASSIGN   (* mudryk    -= *)
  | OP_EQ           (* transfermarkt == *)
  | OP_NEQ          (* vendehumo     != *)
  | OP_GT           (* barredora     >  *)
  | OP_GEQ          (* amarilla      >= *)
  | OP_LT           (* roja          <  *)
  | OP_LEQ          (* zancadilla    <= *)
  | OP_AND          (* pase          && *)
  | OP_OR           (* sombrero      || *)
  | LPAREN          (* (  *)
  | RPAREN          (* )  *)
  | LBRACE          (* {  *)
  | RBRACE          (* }  *)
  | COMMA           (* centro  ,  *)
  | SEMICOLON       (* !  fin de sentencia *)
  | INT_LIT  of int
  | STR_LIT  of string
  | BOOL_LIT of bool
  | IDENT    of string
  | EOF

(* ── Operadores binarios del AST ── *)
type binop =
  | Add | Sub | Mul | Div | Mod | Concat
  | Eq  | Neq | Lt  | Gt  | Leq | Geq
  | And | Or

(* ── Expresiones ── *)
type expr =
  | IntLit  of int
  | StrLit  of string
  | BoolLit of bool
  | Var     of string
  | BinOp   of binop * expr * expr
  | Call    of string * expr list   (* Fase 2 *)

(* ── Sentencias ── *)
type stmt =
  | Decl            of string * expr
  | Assign          of string * expr
  | CompoundAssign  of string * binop * expr
  | IncDec          of string * [`Inc | `Dec]
  | Print           of expr
  | If              of (expr * stmt list) * (expr * stmt list) list * stmt list option
  | While           of stmt option * expr * stmt list
  | For             of stmt * expr * stmt * stmt list
  | Block           of stmt list
  | Return          of expr option   (* Fase 2 *)
  | ExprStmt        of expr          (* Fase 2 *)

(* ── Funciones (Fase 2) ── *)
type func_def = {
  name   : string;
  params : string list;
  body   : stmt list;
}

type top_elem =
  | TopStmt of stmt
  | TopFunc of func_def

(* ── Valores en runtime ── *)
module StringMap = Map.Make(String)

type value =
  | VInt    of int
  | VString of string
  | VBool   of bool

type env = value StringMap.t
