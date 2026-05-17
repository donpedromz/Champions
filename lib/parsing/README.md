# Módulo `Parsing` (Parser)

**Ubicación:** `lib/parsing/`

## Responsabilidad

Convierte la lista de tokens (`token list`) producida por el lexer en un **Árbol de Sintaxis Abstracta** (`stmt list`) definido en `types.ml`. Implementa un **parser recursivo descendente** (*recursive descent parser*): cada regla gramatical se traduce en una función de OCaml.

---

## Punto de entrada

### `parse : token list -> stmt list`

```ocaml
let ast = Parser.parse tokens
```

Lanza `Parser.ParseError msg` si la secuencia de tokens no respeta la gramática del lenguaje.

---

## Gramática en BNF

### Programa

```bnf
<program>   ::= <stmt>* EOF
<stmt>      ::= <decl>
             |  <assign>
             |  <compound-assign>
             |  <incdec>
             |  <print>
             |  <block>
             |  <if>
             |  <while>
             |  <for>
```

### Declaración

```bnf
<decl>      ::= pasar_balon IDENT a <expr> !
```

### Asignaciones

```bnf
<assign>          ::= IDENT a <expr> !
<compound-assign>  ::= IDENT tikitaka <expr> !
                   |  IDENT mudryk <expr> !
<incdec>          ::= IDENT ofensiva !
                   |  IDENT defensiva !
```

### Impresión

```bnf
<print>     ::= gritar_gol ( <expr> ) !
```

### Bloque

```bnf
<block>     ::= { <stmt>* }
```

### Condicional

```bnf
<if>        ::= ataca_cr7 ( <expr> ) <block>
                [ defiende_cr7 ( <expr> ) <block> ]*
                [ amaga_cr7 <block> ]
```

### Bucles

```bnf
<while>     ::= ataca_el_atleti ( [pasar_balon IDENT a <expr> !] <expr> ) <block>

<for>       ::= ataca_el_arsenal (
                  pasar_balon IDENT a <expr> !
                  <expr> !
                  IDENT (ofensiva | defensiva)
                ) <block>
```

> **Nota sobre `while`:** admite un *header dual* donde la declaración de la variable de control puede ir dentro del paréntesis, antes de la condición.

### Expresiones (por precedencia)

```bnf
<expr>      ::= <or-expr>

<or-expr>   ::= <and-expr> ( sombrero <and-expr> )*

<and-expr>  ::= <cmp-expr> ( pase <cmp-expr> )*

<cmp-expr>  ::= <add-expr>
               [ ( transfermarkt | vendehumo | roja | barredora | zancadilla | amarilla ) <add-expr> ]

<add-expr>  ::= <mul-expr> ( ( cabeceo | rabona | mbappe ) <mul-expr> )*

<mul-expr>  ::= <factor> ( ( chilena | penalti | volea ) <factor> )*

<factor>    ::= INT_LIT
             |  STR_LIT
             |  BOOL_LIT
             |  IDENT
             |  ( <expr> )
```

---

## Tabla de precedencia de operadores

| Nivel | Operador | Palabra | Asociatividad |
|-------|----------|---------|---------------|
| 6 (más bajo) | `\|\|` | `sombrero` | Izquierda |
| 5 | `&&` | `pase` | Izquierda |
| 4 | `==`, `!=`, `<`, `>`, `<=`, `>=` | `transfermarkt`, `vendehumo`, `roja`, `barredora`, `zancadilla`, `amarilla` | Izquierda¹ |
| 3 | `+`, `-`, `^` | `cabeceo`, `rabona`, `mbappe` | Izquierda |
| 2 | `*`, `/`, `%` | `chilena`, `penalti`, `volea` | Izquierda |
| 1 (más alto) | `( ... )` | agrupación | — |

¹ Los operadores relacionales no se encadenan implícitamente; cada comparación es binaria.

---

## Arquitectura interna

### Estado del parser

```ocaml
type parser_state = { mutable tokens : token list }
```

Mantiene la lista de tokens restantes como referencia mutable.

### Funciones auxiliares

| Función | Descripción |
|-----------|-------------|
| `peek ps` | Observa el token actual sin consumirlo |
| `advance ps` | Consume y retorna el token actual |
| `expect ps tok` | Consume `tok` o lanza `ParseError` |
| `check ps tok` | Verifica si el token actual es `tok` |
| `match_token ps tok` | Consume `tok` si coincide; retorna `bool` |

### Funciones de parsing

Cada nivel de precedencia tiene su propia función:

- `parse_expr` → entrada a la jerarquía de expresiones
- `parse_or`, `parse_and`, `parse_comparison`, `parse_addition`, `parse_multiplication`, `parse_factor`

Cada sentencia tiene su parser dedicado:

- `parse_declaration`, `parse_print`, `parse_block`
- `parse_if`, `parse_while`, `parse_for`
- `parse_statement` (dispatch principal)

### Parseo de listas de sentencias

```ocaml
parse_statements_until ps stop
```

Acumula sentencias hasta encontrar el token de cierre (`RBRACE`, `EOF`, etc.).

---

## Errores de sintaxis

El parser lanza `ParseError "descripción"` con mensajes descriptivos del estilo:

```
Se esperaba RPAREN pero se encontró SEMICOLON
Expresión inesperada: OP_ADD
Sentencia inesperada después de 'x': EOF
```

Esto facilita la depuración del código fuente `.cr7`.

---

## Casos delicados cubiertos

- **Precedencia:** `2 cabeceo 3 chilena 4` se parsea como `2 + (3 * 4)`.
- **Asociatividad izquierda:** `10 rabona 3 rabona 2` se parsea como `(10 - 3) - 2`.
- **If-elif-else encadenado:** la lista de `defiende_cr7` se acumula en orden correcto.
- **While dual:** distingue automáticamente entre header con `pasar_balon` y header simple.
- **For estricto:** valida que el `update` sea exactamente `ofensiva` o `defensiva`.
- **Bloques vacíos:** `{}` produce `Block []`.
