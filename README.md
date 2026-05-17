# Champions Language

Intérprete del lenguaje de programación **Champions**, diseñado con sintaxis inspirada en el fútbol. El proyecto está implementado en **OCaml** y utiliza **Dune** como sistema de compilación.

---

## Requisitos previos

Antes de compilar y ejecutar el intérprete, necesitas instalar:

| Herramienta | Versión mínima | Propósito |
|-------------|---------------|-----------|
| **OCaml** | 4.14+ | Compilador del lenguaje |
| **OPAM** | 2.1+ | Gestor de paquetes de OCaml |
| **Dune** | 3.0+ | Sistema de compilación |

### Instalación rápida (Windows)

1. **Instalar OCaml y OPAM:**
   Descarga e instala desde [https://fdopen.github.io/opam-repository-mingw/](https://fdopen.github.io/opam-repository-mingw/) (versión para Windows) o usa el instalador oficial de OCaml.

2. **Inicializar OPAM** (solo la primera vez):
   ```powershell
   opam init
   ```

3. **Crear un switch de OCaml** (entorno aislado):
   ```powershell
   opam switch create champions ocaml-system
   eval $(opam env --switch=champions)
   ```

4. **Instalar Dune:**
   ```powershell
   opam install dune
   ```

---

## Activación del entorno

> **Importante:** Cada vez que abras una nueva terminal, debes activar el entorno de OPAM antes de compilar o ejecutar.

### En PowerShell (Windows):

```powershell
(& opam env) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
```

### En Bash / Zsh (Linux / macOS):

```bash
eval $(opam env)
```

Verifica que Dune esté disponible:

```powershell
dune --version
```

---

## Estructura del proyecto

El intérprete está dividido en **tres fases modulares**, cada una con su propia carpeta bajo `lib/` siguiendo el principio de **separación de responsabilidades**:

```
Champions/
├── lib/                          # Raíz de la biblioteca
│   └── dune                      # Configura include_subdirs unqualified
│
├── lib/types/                    # Fase 0: Tipos compartidos
│   ├── types.ml                  # Tokens, AST, valores, entorno
│   └── README.md                 # Documentación del contrato compartido
│
├── lib/tokenization/             # Fase 1: Tokenización
│   ├── lexer.ml                  # Lexer recursivo con tabla de keywords
│   └── README.md                 # Documentación del proceso de tokenización
│
├── lib/parsing/                  # Fase 2: Análisis sintáctico
│   ├── parser.ml                 # Parser recursivo descendente
│   └── README.md                 # Gramática BNF y arquitectura del parser
│
├── lib/evaluation/               # Fase 3: Evaluación (reservado)
│   └── README.md                 # Instrucciones de implementación para Persona C
│
├── bin/                          # Ejecutable
│   ├── dune
│   └── main.ml                   # Punto de entrada (pipeline de fases)
│
├── test/                         # Tests unitarios
│   ├── dune
│   ├── test_lexer.ml             # Tests del lexer (Persona A)
│   └── test_parser.ml            # Tests del parser (Persona B)
│
├── examples/                     # Programas de ejemplo .cr7
│   └── basicos.cr7
│
├── dune-project                  # Configuración global del proyecto
└── champions.opam                # Metadatos del paquete OPAM
```

### Modularización

| Fase | Carpeta | Archivo | Responsable | Función |
|------|---------|---------|-------------|---------|
| 0 | `lib/types/` | `types.ml` | Equipo | Tipos compartidos: tokens, AST, valores, entorno |
| 1 | `lib/tokenization/` | `lexer.ml` | Persona A | **Tokenización:** convierte texto fuente en lista de tokens |
| 2 | `lib/parsing/` | `parser.ml` | Persona B | **Parseo:** convierte tokens en AST (árbol de sintaxis abstracta) |
| 3 | `lib/evaluation/` | `eval.ml` | Persona C | **Evaluación:** ejecuta el AST, evalúa expresiones y controla el flujo |

El pipeline en `bin/main.ml` conecta las fases secuencialmente:

```
archivo.cr7  →  [Lexer.tokenize]  →  tokens
                                    ↓
                               [Parser.parse]
                                    ↓
                                    AST
                                    ↓
                                [Eval.run]   (Fase 3 — Persona C)
                                    ↓
                                output + efectos
```

---

## Compilación

Con el entorno de OPAM activo, compila todo el proyecto con:

```powershell
opam exec -- dune build
```

> `opam exec --` ejecuta el comando dentro del entorno de OPAM, garantizando que Dune y las dependencias estén en el PATH.

Si la compilación es exitosa, no se muestra ningún mensaje (compilación silenciosa).

---

## Ejecución del intérprete

### Ejecutar un programa `.cr7`

```powershell
opam exec -- dune exec champions <archivo.cr7>
```

**Ejemplo:**

```powershell
opam exec -- dune exec champions examples/basicos.cr7
```

Salida actual (hasta que se implemente `lib/evaluation/eval.ml`):

```
Análisis sintáctico completado.
Evaluación pendiente: implementar lib/evaluation/eval.ml
```

> Una vez que la **Fase 3** (evaluación) esté implementada por Persona C, la salida será el resultado de la ejecución del programa (impresiones, cálculos, etc.).

### Modo debug: ver tokens

Para inspeccionar la salida del lexer sin pasar al parser:

```powershell
opam exec -- dune exec champions <archivo.cr7> -- --tokens
```

**Ejemplo:**

```powershell
opam exec -- dune exec champions examples/basicos.cr7 -- --tokens
```

Muestra cada token en formato legible:

```
KW_LET(pasar_balon)
IDENT(mensaje)
OP_ASSIGN(a)
STR_LIT("Bienvenido al Champions")
SEMICOLON(!)
...
```

> **Nota:** En Windows, asegúrate de usar `open_in_bin` al leer archivos para evitar errores de `End_of_file` con archivos de texto con terminaciones de línea mixtas.

---

## Tests unitarios

Ejecuta todas las suites de prueba con:

```powershell
opam exec -- dune test
```

Salida esperada:

```
=== Tests del Lexer ===
  PASS: pasar_balon x a 100!
  PASS: ataca_cr7(x zancadilla 7){
  ...
=== Tests del Parser ===
  PASS: 2 + (3 * 4)
  PASS: (10 - 3) - 2
  ...
=== Fin ===
```

---

## Comandos rápidos de referencia

| Acción | Comando |
|--------|---------|
| Activar entorno OPAM (PowerShell) | `(& opam env) -split '\r?\n' \| ForEach-Object { Invoke-Expression $_ }` |
| Activar entorno OPAM (Bash) | `eval $(opam env)` |
| Compilar | `opam exec -- dune build` |
| Ejecutar tests | `opam exec -- dune test` |
| Ejecutar programa | `opam exec -- dune exec champions <archivo.cr7>` |
| Ver tokens | `opam exec -- dune exec champions <archivo.cr7> -- --tokens` |
| Limpiar build | `opam exec -- dune clean` |

---

## Ejemplo mínimo de programa Champions

Archivo: `hola.cr7`

```champions
pasar_balon mensaje a "Hola, Champions"!
gritar_gol(mensaje)!
```

Ejecución:

```powershell
opam exec -- dune exec champions hola.cr7
```

Salida:

```
Hola, Champions
```

---

## Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `dune : The term is not recognized` | OPAM no está activado | Ejecuta `(& opam env) -split '\r?\n' \| ForEach-Object { Invoke-Expression $_ }` |
| `Fatal error: exception End_of_file` | Lectura de archivo en modo texto en Windows | Usar `open_in_bin` en lugar de `open_in` |
| `ParseError("Sentencia inesperada...")` | Sintaxis inválida en `.cr7` | Revisar gramática en `lib/README_PARSER.md` |
| `Eval.RuntimeError("Variable no definida...")` | Uso de variable sin declarar (Fase 3) | Declarar con `pasar_balon` antes de usar |

---

## Documentación adicional

- `lib/types/README.md` — Tokens, AST, valores y entorno.
- `lib/tokenization/README.md` — Proceso de tokenización, tabla de palabras reservadas.
- `lib/parsing/README.md` — Gramática BNF completa, precedencia de operadores, arquitectura del parser.
- `lib/evaluation/README.md` — Instrucciones de implementación para el evaluador.

---

## Autores

- **Persona A** — Lexer (`lib/tokenization/lexer.ml`)
- **Persona B** — Parser (`lib/parsing/parser.ml`)
- **Persona C** — Evaluador (`lib/evaluation/eval.ml`)
