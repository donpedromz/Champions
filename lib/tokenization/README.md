# Módulo `Tokenization` (Lexer)

**Ubicación:** `lib/tokenization/`

## Responsabilidad

Convierte el **código fuente** del lenguaje Champions en una **lista de tokens** (`token list`) que el parser consume. Es la primera fase del front-end.

---

## Funciones principales

### `tokenize : string -> token list`

Recibe el contenido completo de un archivo `.cr7` y retorna la lista de tokens terminada en `EOF`.

```ocaml
let tokens = Lexer.tokenize source_code
```

Lanza `Lexer.LexError msg` si encuentra un carácter no reconocido, un string sin cerrar, etc.

### `string_of_token : token -> string`

Convierte un token a una representación legible para depuración. Se usa en modo `--tokens` y en mensajes de error del parser.

---

## Proceso de tokenización

### 1. Salto de espacios y comentarios

- Espacios, tabulaciones, retornos de carro y saltos de línea se omiten.
- Comentarios de línea comienzan con `#` y terminan al final de la línea.

### 2. Reconocimiento de tokens

| Patrón | Token generado |
|--------|----------------|
| `(`, `)`, `{`, `}` | `LPAREN`, `RPAREN`, `LBRACE`, `RBRACE` |
| `!` | `SEMICOLON` (fin de sentencia) |
| `"..."` | `STR_LIT` (con soporte de escapes `\n`, `\t`, `\"`, `\\`) |
| Dígitos `[0-9]+` | `INT_LIT` |
| Palabra reservada | Token según la tabla de keywords |
| Identificador `[A-Za-z_][A-Za-z0-9_]*` | `IDENT` |
| Cualquier otro carácter | `LexError` |

### 3. Tabla de palabras reservadas (`keywords`)

El lexer mantiene una asociación de strings a tokens. Algunos ejemplos destacados:

```ocaml
("pasar_balon",  KW_LET);
("gritar_gol",   KW_PRINT);
("ataca_cr7",    KW_IF);
("defiende_cr7", KW_ELSE_IF);
("amaga_cr7",    KW_ELSE);
("cabeceo",      OP_ADD);
("rabona",       OP_SUB);
("tikitaka",     OP_ADD_ASSIGN);
("mudryk",       OP_SUB_ASSIGN);
("gol",          BOOL_LIT true);
("autogol",      BOOL_LIT false);
```

> **Nota:** Los identificadores de usuario deben **evitar** estas palabras reservadas.

---

## Excepciones

| Excepción | Cuándo ocurre |
|-----------|---------------|
| `LexError` | Carácter no reconocido, string sin cerrar, secuencia de escape inválida |

Todos los errores incluyen **línea y columna** del problema.

---

## Verbosidad de salida

Modo `--tokens` en el ejecutable principal (`bin/main.ml`) permite inspeccionar la salida del lexer token por token.
