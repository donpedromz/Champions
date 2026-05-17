# Módulo `Evaluation` (Evaluador)

**Ubicación:** `lib/evaluation/`

## Responsabilidad

Este módulo está reservado para la **Fase 3** del intérprete: la **evaluación y ejecución** del AST (`stmt list`) producido por el parser.

> **Responsable:** Persona C

---

## Instrucciones de implementación

### 1. Crear `eval.ml`

En esta carpeta (`lib/evaluation/`) crea un archivo `eval.ml` que implemente la semántica operacional del lenguaje Champions.

```ocaml
open Types
```

### 2. Contrato esperado

Debes exportar al menos una función:

```ocaml
val run : stmt list -> unit
```

`run` recibe la lista de sentencias del programa (el AST) y ejecuta el código, produciendo efectos laterales (impresiones en consola vía `gritar_gol`) y manteniendo el estado del entorno.

### 3. Entorno inmutable

Usa `StringMap` definido en `types.ml`:

```ocaml
module Env = StringMap
type env = value StringMap.t
```

Cada `Decl` o `Assign` debe retornar un **nuevo** entorno, no mutar el existente.

### 4. Estructura recomendada

```ocaml
(* excepción para errores de ejecución *)
exception RuntimeError of string

(* evaluar expresiones *)
let rec eval_expr env = function
  | IntLit n   -> VInt n
  | StrLit s   -> VString s
  | BoolLit b  -> VBool b
  | Var name   -> ... (* buscar en Env *)
  | BinOp (op, l, r) -> ... (* evaluar l y r, aplicar operador *)

(* evaluar sentencias *)
let rec eval_stmt env = function
  | Decl (name, expr)       -> Env.add name (eval_expr env expr) env
  | Assign (name, expr)     -> ... (* verificar que exista antes *)
  | CompoundAssign (name, op, expr) -> ... (* tikitaka / mudryk *)
  | IncDec (name, dir)      -> ... (* ofensiva / defensiva *)
  | Print expr              -> ... (* imprimir en consola *)
  | If (then_branch, elifs, else_opt) -> ... (* condicionales *)
  | While (init_opt, cond, body) -> ... (* bucle while *)
  | For (init, cond, update, body) -> ... (* bucle for *)
  | Block stmts             -> ... (* evaluar lista de sentencias *)
  | _ -> ... (* Fase 2: Return, ExprStmt, Call *)

(* punto de entrada público *)
let run program =
  ignore (List.fold_left eval_stmt Env.empty program)
```

### 5. Consideraciones importantes

- **Tipado dinámico:** las expresiones pueden producir `VInt`, `VString` o `VBool`. Verificar compatibilidad de tipos en cada operación (ej. no sumar string + int directamente, salvo en concatenación).
- **Concatenación (`mbappe`):** debe funcionar entre strings, y opcionalmente string+int / int+string.
- **Control de flujo:** `If`/`While`/`For` requieren que la condición evalúe a `VBool`. Si no, lanzar `RuntimeError`.
- **While dual:** `While of stmt option * expr * stmt list` — si hay `init_opt`, evaluarlo antes de entrar al bucle.
- **Scope:** Por ahora no hay scopes anidados (Fase 2 lo agregará). Todo el programa comparte el mismo entorno global.
- **Mensajes de error claros:** incluir nombre de variable u operación que falló.

### 6. Integración con `main.ml`

Una vez implementado `eval.ml`, actualiza `bin/main.ml` para llamar:

```ocaml
Champions.Eval.run ast;
```

Después de la fase de parseo y captura `Eval.RuntimeError` para mostrar errores en tiempo de ejecución.

### 7. Tests

Crea tests en `test/test_eval.ml` siguiendo el patrón de `test_parser.ml`. Construye ASTs a mano y verifica:
- Valor final del entorno después de `run`.
- Salida por consola capturada (opcional, puede ser manual).
- Errores de runtime (división por cero, variable no definida, etc.).

---

## Dependencias

- `lib/types/types.ml` — tokens, AST, valores, entorno.
- `lib/tokenization/lexer.ml` — no directamente, pero útil para tests integrados.
- `lib/parsing/parser.ml` — no directamente, pero útil para tests integrados.
