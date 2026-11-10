# Pi to C transpiler

Andreadakis Antonios, 2013030059 — Computation Theory course project.

## Description

A transpiler for the teaching language **Pi**, built with flex and bison.
It reads a `.pi` program, checks it for lexical and syntax errors and, if there
are none, translates it to C. The C file can then be compiled with gcc and run.

| File | Role |
|---|---|
| `mylexer.l` | flex lexer: keywords, identifiers, numbers, strings, operators, comments |
| `myanalyzer.y` | bison grammar; each rule builds the C text for what it parsed |
| `cgen.c`, `cgen.h` | helpers for building strings and reporting errors |
| `pilib.h` | runtime library included by the generated C (`readInt`, `writeString`, ...) |
| `*.pi` | sample Pi programs |

## Requirements

`flex`, `bison`, `gcc` and `make` (on Debian/Ubuntu: `sudo apt install flex bison gcc make`).

## Usage

Build the transpiler:

```bash
make
```

Translate a Pi program to C (the C code goes to stdout, messages to stderr):

```bash
./mycompiler < prime.pi > prime.c
```

Compile and run the result (`-I.` finds `pilib.h`, `-lm` is needed for `**`):

```bash
gcc -I. -o prime prime.c -lm
./prime
```

Translate and compile all the samples into `build/`:

```bash
make test
```

`mycompiler` prints `Accepted!` and exits with code 0 on success. On an error it
prints the line number and the reason, then `Rejected!`, exits with code 1 and
produces no C code.

## How the translation works

- `func begin()` is the entry point. It becomes `pi_begin()`, called from a
  generated `int main(void)`.
- A prototype is emitted for every function, so functions may be defined in any
  order, before or after `begin`.
- Types: `int` -> `int`, `real` -> `double`, `bool` -> `int`, `string` -> `char*`.
- `a ** b` becomes `pow(a, b)`; `and`, `or`, `not` become `&&`, `||`, `!`.
- The body of every `if`, `while` and `for` is emitted inside braces.

## Design notes

- The grammar has **no shift/reduce or reduce/reduce conflicts**. The rule that
  makes this possible: an expression never produces a `;`, a statement always
  does. A `;` after a closing `}` is optional and treated as an empty statement.
- The dangling `else` is resolved with precedence (`%prec THEN`): an `else`
  belongs to the nearest `if`.
- Operator precedence, lowest to highest: `or`; `and`; `== !=`; `< <= > >=`;
  `+ -`; `* / %`; `**` (right associative); unary `not + -` and casts.
  Assumption: `== !=` bind looser than `< <= > >=`, as in C, so that the
  generated C text means exactly what was parsed.

## Known limitations

- No semantic checks (undeclared variables, type errors); those are reported by
  gcc when the generated C is compiled.
- Strings built by the code generator are never freed. This is fine for a
  program that runs once and exits.
