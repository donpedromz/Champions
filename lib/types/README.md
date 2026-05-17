# Módulo `Types`

**Ubicación:** `lib/types/`

## Responsabilidad

Define el **contrato compartido** entre Lexer, Parser y Evaluador de Champions. Contiene todas las estructuras de datos que fluyen a través de las fases del compilador/intérprete.

> ⚠️ **NO modificar sin acuerdo del equipo.** Cualquier cambio en este archivo afecta directamente a `tokenization/`, `parsing/` y `evaluation/`.

---

## Tipos principales

### Tokens (`token`)

El lexer produce una lista de estos tokens a partir del texto fuente. Consulta el README de `tokenization/` para la tabla completa de palabras reservadas y delimitadores.

### AST (Árbol de Sintaxis Abstracta)

#### Operadores binarios (`binop`)

```ocaml
type binop =
  | Add | Sub | Mul | Div | Mod | Concat
  | Eq  | Neq | Lt  | Gt  | Leq | Geq
  | And | Or
```

#### Expresiones (`expr`)

| Constructor | Significado |
|-------------|-------------|
| `IntLit of int` | Literal entero |
| `StrLit of string` | Literal cadena |
| `BoolLit of bool` | Literal booleano |
| `Var of string` | Variable (referencia) |
| `BinOp of binop * expr * expr` | Operación binaria |
| `Call of string * expr list` | Llamada a función (Fase 2) |

#### Sentencias (`stmt`)

| Constructor | Significado |
|-------------|-------------|
| `Decl of string * expr` | `pasar_balon id a expr !` |
| `Assign of string * expr` | `id a expr !` |
| `CompoundAssign of string * binop * expr` | `id tikitaka expr !` / `id mudryk expr !` |
| `IncDec of string * [`\`Inc | `\`Dec]` | `id ofensiva !` / `id defensiva !` |
| `Print of expr` | `gritar_gol(expr) !` |
| `If of (expr * stmt list) * (expr * stmt list) list * stmt list option` | Condicional con elif/else |
| `While of stmt option * expr * stmt list` | Bucle while con init opcional |
| `For of stmt * expr * stmt * stmt list` | Bucle for |
| `Block of stmt list` | Bloque `{ ... }` |
| `Return of expr option` | `saque expr` (Fase 2) |
| `ExprStmt of expr` | Expresión como sentencia (Fase 2) |

---

## Runtime

### Valores (`value`)

```ocaml
type value =
  | VInt    of int
  | VString of string
  | VBool   of bool
```

### Entorno (`env`)

Mapa inmutable de identificadores a valores:

```ocaml
module StringMap = Map.Make(String)
type env = value StringMap.t
```

Cada `Decl` o `Assign` genera un **nuevo** entorno.
