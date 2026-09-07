# Informe de Ejecución de Pruebas — Compilador Progress OpenEdge 12.8

**Fecha:** 07/09/2026
**Entorno:** `C:\Progress\OpenEdge` — `PROVERSION 12.8`
**Comando ejecutado:** `prowin.exe -b -p tests/TestRunner.p` (desde la raíz del repositorio)
**Estado:** los 4 hallazgos originales fueron corregidos y verificados con una segunda ejecución real (ver [Estado final tras las correcciones](#estado-final-tras-las-correcciones)).

## Resumen ejecutivo

Al intentar ejecutar la suite tal como estaba en el repositorio, **no arrancaba**: dos errores de sintaxis ABL impedían compilar `tests/TestRunner.p` y `src/config/ConfigManager.i`. Se corrigieron ambos (ver [Correcciones aplicadas](#correcciones-aplicadas-bloqueantes-necesarias-solo-para-poder-ejecutar)) para poder obtener una primera ejecución real. Con esas dos correcciones mínimas (y solo esas dos), el resultado observado fue:

| Suite | Aserciones | Resultado |
|---|---|---|
| `test_rules_engine.p` | 17 | ✅ Todas pasan |
| `test_propath_manager.p` | 8 | ✅ Todas pasan |
| `test_config_manager.p` | 17 | ✅ Todas pasan (con 1 advertencia de runtime no fatal) |
| `test_build_logger.p` | 8 | ✅ Todas pasan |
| `test_build_engine.p` | 9 | ❌ **3 fallan** |
| `test_regression.p` | 10 | ✅ Todas pasan |
| **Total observado** | **69** | **66 PASS / 3 FAIL** |

El resumen final que imprimía el propio `TestRunner.p` en ese momento (`Resumen de Pruebas: Aserciones=0 Pasadas=0 Falladas=0 — ESTADO FINAL: EXITO`) **no era fiable**: un bug del arnés de pruebas (hallazgo #4) hacía que el runner reportara siempre éxito y saliera con código 0 aunque hubiera fallos reales. Los conteos de la tabla anterior se obtuvieron contando manualmente las líneas `[PASS]`/`[FAIL]` de esa salida (ver [Salida completa de la primera ejecución](#salida-completa-de-la-primera-ejecución-solo-con-las-2-correcciones-bloqueantes)).

A petición del usuario, se aplicaron a continuación las 3 correcciones restantes (hallazgos #1, #2 y #4 de la sección siguiente). Tras aplicarlas, una nueva ejecución real dio **69/69 aserciones pasadas, agregado correctamente por el propio runner** — ver el detalle en [Estado final tras las correcciones](#estado-final-tras-las-correcciones).

## Correcciones aplicadas (bloqueantes, necesarias solo para poder ejecutar)

Estas dos correcciones fueron indispensables porque impedían compilar el código; sin ellas no se podía obtener ningún resultado de prueba. Se aplicaron por ser errores de sintaxis objetivos (confirmados contra la [ABL Reference](https://docs.progress.com/bundle/abl-reference/) oficial), no decisiones de diseño.

1. **`QUIT <entero>` no es sintaxis válida en ABL** — la sentencia `QUIT` no acepta parámetros; el código de salida del proceso se fija con `SESSION:EXIT-CODE = <entero>` antes de `QUIT.`. Esto rompía la compilación de:
   - `tests/TestRunner.p` (líneas 57 y 59)
   - `src/cli/RunBuild.p` (líneas 71, 77, 89 y 100)

   Se reemplazó cada `QUIT n.` por `SESSION:EXIT-CODE = n.` seguido de `QUIT.`.

2. **`INPUT FROM ... NO-ERROR` no es una opción válida de `INPUT FROM`** — a diferencia de otras sentencias de E/S, `INPUT FROM` no admite `NO-ERROR` (confirmado en la sintaxis oficial de la sentencia). Esto rompía la compilación de `src/config/ConfigManager.i:85`, y por extensión cualquier suite o programa que incluyera `ConfigManager.i` (`test_config_manager.p`, `test_regression.p`, `RunBuild.p`, `compilador.w`).

   Se quitó `NO-ERROR` de esa línea. El bloque `IF ERROR-STATUS:ERROR THEN DO...` que sigue queda como código muerto defensivo (nunca se activará por esta vía) pero es inofensivo; no se tocó más allá de lo necesario.

Estas correcciones ya están aplicadas en el árbol de trabajo (`tests/TestRunner.p`, `src/cli/RunBuild.p`, `src/config/ConfigManager.i`). No hay control de versiones en este proyecto (`git init` no se ha ejecutado), así que no existe un commit que revertir si se prefiere otro enfoque — el detalle exacto del cambio está arriba.

## Hallazgos — todos corregidos y verificados

### 1. ✅ CORREGIDO — `test_build_engine.p` fallaba: `COMPILE ... SAVE INTO` no generaba el `.r` donde el código lo esperaba

Las 3 aserciones que fallaban:
- `Programa valido debe compilar con exito`
- `El archivo .r debe existir en el directorio de STAGING`
- `El archivo .r debe haberse desplegado en el directorio FINAL`

**Causa raíz (confirmada de forma aislada antes de corregir):** `compileSingleFile` (`src/core/BuildEngine.i`) invocaba `COMPILE VALUE(pcSourceFile) SAVE INTO VALUE(pcStagingDir)` y luego buscaba el `.r` en `pcStagingDir/<nombre_base>.r`. Pero cuando `pcSourceFile` es una ruta relativa con subdirectorio (p. ej. `tests/test_prog_valid.p`, como usa el propio fixture de la prueba), `SAVE INTO` **replica la estructura de subdirectorios de la ruta fuente dentro del directorio de staging**, en vez de guardar el `.r` plano en la raíz de staging. El error real capturado en una ejecución aislada fue:

```
Unable to create r-code file "tests\staging_diag\tests\diag_valid.r". (477)
```

Es decir: el compilador intentaba crear `staging/tests/archivo.r` (porque la fuente estaba en `tests/archivo.p`), no `staging/archivo.r` como asumía `vc_staged_r` en el código. Como el subdirectorio `tests/` no existía dentro de staging, la creación del `.r` fallaba con error 477.

**Impacto real:** no era solo un problema del fixture de prueba — era un defecto real en `BuildEngine.i` que afectaba a cualquier compilación real donde `source` se pasara como ruta relativa con subdirectorios (el caso normal de uso vía CLI, `source=<dir_o_archivo>`).

**Corrección aplicada:** se verificó empíricamente que compilar con la ruta fuente resuelta a **absoluta** hace que `SAVE INTO` guarde el `.r` siempre de forma plana (sin replicar subdirectorios). En `compileSingleFile` (`src/core/BuildEngine.i`) se añadió, antes de la sentencia `COMPILE`, una resolución de `pcSourceFile` a ruta absoluta vía `FILE-INFO:FULL-PATHNAME` (con fallo temprano y mensaje claro si el archivo no se localiza en disco), y ambas ramas de `COMPILE` (`V6FRAME` y normal) ahora compilan `VALUE(vc_abs_source)` en vez de `VALUE(pcSourceFile)`. `vc_staged_r`/`vc_deploy_r` no cambiaron (siguen siendo planos, como se esperaba).

### 2. ✅ CORREGIDO — Advertencia de runtime en `ConfigManager.i:loadCatalog` — `HAS-RECORDS` sobre un buffer

Al ejecutar `test_config_manager.p` (y cualquier llamada a `loadCatalog`), la consola emitía:

```
** HAS-RECORDS is not a queryable attribute for BUFFER widget. (4052)
```

**Causa:** `ConfigManager.i` construía el mensaje de éxito con `TEMP-TABLE tt_sistema:DEFAULT-BUFFER-HANDLE:HAS-RECORDS`. `HAS-RECORDS` no es un atributo válido sobre el *handle de buffer* por defecto de una temp-table estática.

**Corrección aplicada:** se reemplazó ese cálculo por un conteo explícito por iteración (`FOR EACH tt_sistema NO-LOCK: ... END.` acumulando en una variable `INTEGER`), evitando la ambigüedad del atributo por completo. El mensaje sigue reportando el número de sistemas cargados, ahora sin advertencia de runtime. Esto también resuelve el hallazgo #3 original (el mismo warning aparecía en cualquier build headless vía `RunBuild.p system=<nombre>`, al reutilizar `loadCatalog`).

### 3. ✅ CORREGIDO — `TestRunner.p` no agregaba resultados entre suites — el resumen final y el código de salida siempre eran "éxito"

Cada `test_*.p` se ejecuta con `RUN tests/test_xxx.p`, y cada uno incluye su propia copia de `{tests/Assert.i}`. En ABL, las variables `DEFINE`d dentro de un include son privadas de cada procedimiento externo compilado; al no ser compartidas, los contadores (`gi_asserts_count`, `gi_tests_passed`, `gi_tests_failed`) que cada suite incrementaba **vivían solo en la memoria de esa suite y se perdían al retornar**. `TestRunner.p` tenía su propia copia de esos contadores, inicializados en 0, y como nunca ejecutaba un `assertXxx` directamente, jamás se incrementaban.

**Consecuencia observada antes de corregir:** el resumen final siempre imprimía `Aserciones=0 Pasadas=0 Falladas=0` y `ESTADO FINAL: EXITO`, y `SESSION:EXIT-CODE` siempre quedaba en `0` — incluso en la ejecución que tuvo 3 fallos reales.

**Alternativas evaluadas y descartadas:**
- `DEFINE SHARED VARIABLE` / `NEW SHARED VARIABLE`: se confirmó (ABL Reference + prueba empírica) que una variable `SHARED` sin `NEW` busca hacia arriba en la cadena de invocación un `NEW SHARED`/`NEW GLOBAL SHARED` — si un `test_*.p` se ejecuta de forma standalone (`prowin -b -p tests/test_xxx.p`, sin pasar por `TestRunner.p`), no hay tal ancestro y la compilación falla. Habría roto la ejecución individual de archivos.
- `DEFINE OUTPUT PARAMETER` en cada `test_*.p`: se confirmó empíricamente que un procedimiento `.p` ejecutado como *startup procedure* de nivel superior (`-p archivo.p`) **no puede declarar parámetros** — falla con `Mismatched number of parameters passed to routine (3234)`. También habría roto la ejecución standalone.
- `&GLOBAL-DEFINE` como bandera de contexto: se confirmó empíricamente que su alcance NO se propaga a un `.p` ejecutado por separado vía `RUN` (se comporta como `&SCOPED-DEFINE` a estos efectos) — no servía para distinguir "ejecutado por TestRunner" de "ejecutado standalone".

**Corrección aplicada:** en `tests/Assert.i` se añadió un procedimiento `getAssertTotals` (puramente aditivo, no cambia nada existente) que expone los tres contadores locales vía `OUTPUT PARAMETER`. En `tests/TestRunner.p` se añadió un procedimiento interno `runSuite` que ejecuta cada suite con `RUN VALUE(pcSuitePath) PERSISTENT SET vh_suite` (en vez de `RUN ... NO-ERROR` simple) — esto corre el bloque principal de la suite exactamente igual que antes (todas las aserciones se ejecutan igual), pero mantiene el procedimiento residente después; inmediatamente se llama a `RUN getAssertTotals IN vh_suite (...)` para leer sus totales, se acumulan en los contadores propios de `TestRunner.p`, y se libera con `DELETE PROCEDURE`. Se verificó primero en aislamiento (un mini-arnés de prueba de 3 líneas) y luego en el árbol real. La ejecución standalone de un `test_*.p` individual (sin pasar por `TestRunner.p`) se probó de nuevo tras el cambio y sigue funcionando sin modificaciones.

## Estado de artefactos generados por las pruebas

`test_build_engine.p` y `test_config_manager.p` limpian sus propios archivos de fixture pero no los directorios/carpetas que crean (`tests/staging_test/`, `tests/deploy_test/`, `tests/util/`) — comportamiento ya documentado en `CLAUDE.md`, no es un bug nuevo ni algo que se haya corregido aquí. Se eliminaron manualmente después de cada ejecución de este informe para mantener el árbol de trabajo limpio; volverán a aparecer la próxima vez que se corra la suite completa.

## Salida completa de la primera ejecución (solo con las 2 correcciones bloqueantes)

```
==================================================
INICIANDO SUITE DE PRUEBAS AUTOMATIZADAS TDD
Entorno OpenEdge PROVERSION: 12.8
Fecha y Hora: 07/09/2026 14:59:13
==================================================
Ejecutando todas las suites registradas...
--- Ejecutando test_rules_engine.p ---
  [PASS] Extension .p debe ser compilable
  [PASS] Extension .w debe ser compilable
  [PASS] Extension .cls debe ser compilable
  [PASS] Extension .i NO debe ser compilable
  [PASS] Extension .inc NO debe ser compilable
  [PASS] Extension .txt NO debe ser compilable
  [PASS] Extension .csv NO debe ser compilable
  [PASS] Extension .r NO debe ser compilable
  [PASS] Archivo en directorio raiz 'util/' NO debe ser compilable
  [PASS] Archivo con separador Windows 'util\' NO debe ser compilable
  [PASS] Archivo en subdirectorio 'src/util/' NO debe ser compilable
  [PASS] Archivo en subdirectorio 'src\util\' NO debe ser compilable
  [PASS] Archivo en 'modulo1/submodulo/util/' NO debe ser compilable
  [PASS] Directorio 'utilities' NO debe confundirse con 'util'
  [PASS] Nombre de archivo 'utilidad.p' NO debe ser excluido
  [PASS] Debe incluir opcion V6FRAME cuando el codigo contiene el token
  [PASS] NO debe incluir V6FRAME si el codigo no contiene el token
--- Fin test_rules_engine.p ---
--- Ejecutando test_propath_manager.p ---
  [PASS] Debe eliminar duplicados manteniendo el primer orden de aparicion
  [PASS] Debe recortar espacios en blanco y eliminar duplicados
  [PASS] Debe unificar separadores y reconocer duplicados con diferente diagonal
  [PASS] Debe detectar que existe al menos una ruta inexistente
  [PASS] La ruta inexistente debe reportarse en la lista de invalidas
  [PASS] Todas las rutas existentes deben validar en TRUE
  [PASS] No debe haber rutas invalidas reportadas
  [PASS] PROPATH efectivo estricto debe omitir rutas inexistentes y duplicados
--- Fin test_propath_manager.p ---
--- Ejecutando test_config_manager.p ---
  [PASS] La version objetivo por defecto debe ser OpenEdge 12.8
  [PASS] OpenEdge 12.8 debe ser soportado explicitamente
  [PASS] OpenEdge 11 debe ser permitido
  [PASS] OpenEdge 9 debe ser permitido por retrocompatibilidad
  [PASS] No debe limitarse a 9, 11 o 12; versiones futuras deben permitirse
**HAS-RECORDS is not a queryable attribute for BUFFER widget. (4052)
  [PASS] Debe cargar catalogo CSV correctamente
  [PASS] Debe encontrar sistema VENTAS
  [PASS] Directorio fuente correcto para VENTAS
  [PASS] Directorio destino correcto para VENTAS
  [PASS] Propath extra correcto para VENTAS
  [PASS] Sistema no registrado no debe ser encontrado
  [PASS] Debe generar respaldo del catalogo CSV
  [PASS] Debe retornar la ruta del archivo .bak generado
  [PASS] El archivo de respaldo fisico debe existir en disco
  [PASS] Debe agregar o actualizar nuevo sistema en el catalogo
  [PASS] El sistema CONTABILIDAD debe existir tras ser agregado
  [PASS] Directorio fuente de CONTABILIDAD
--- Fin test_config_manager.p ---
--- Ejecutando test_build_logger.p ---
  [PASS] Build ID debe inicializarse correctamente
  [PASS] Total exitosos debe ser 1
  [PASS] Total fallidos debe ser 1
  [PASS] El archivo de reporte fisico debe existir en disco
  [PASS] El reporte debe incluir la version de OpenEdge (PROVERSION)
  [PASS] El reporte debe incluir el PROPATH efectivo
  [PASS] El reporte debe incluir el detalle del archivo fallido
  [PASS] El reporte debe registrar el codigo de error estructurado
--- Fin test_build_logger.p ---
--- Ejecutando test_build_engine.p ---
  [FAIL] Programa valido debe compilar con exito
  [FAIL] El archivo .r debe existir en el directorio de STAGING
  [FAIL] El archivo .r debe haberse desplegado en el directorio FINAL
  [PASS] Programa con error de sintaxis debe reportar fallo en compilacion
  [PASS] El artefacto fallido NUNCA debe desplegarse en destino final
  [PASS] Programa en subdirectorio 'util' debe ser omitido
  [PASS] Programa en 'util' no debe ser desplegado
  [PASS] Archivo .i debe ser omitido
  [PASS] Archivo .i no debe ser desplegado
--- Fin test_build_engine.p ---
--- Ejecutando test_regression.p ---
  [PASS] compilador_legacy.w debe conservarse intacto en el workspace
  [PASS] compilador.w refactorizado debe estar presente
  [PASS] util/ptestv6frame.p debe excluirse por pertenecer a carpeta util
  [PASS] Ruta absoluta con /util/ debe ser excluida
  [PASS] Extension .p es compilable
  [PASS] Extension .w es compilable
  [PASS] Extension .cls es compilable para OE 12.8
  [PASS] PROPATH debe incluir src
  [PASS] PROPATH deterministico deduplicado
  [PASS] La version objetivo debe ser 12.8
--- Fin test_regression.p ---
==================================================
--------------------------------------------------
Resumen de Pruebas: Aserciones=0 Pasadas=0 Falladas=0
ESTADO FINAL: EXITO (Todas las pruebas pasaron)
--------------------------------------------------
==================================================
```

## Estado final tras las correcciones

Con los 5 cambios aplicados en total (2 bloqueantes + 3 pendientes: `src/core/BuildEngine.i`, `src/config/ConfigManager.i`, `tests/Assert.i`, `tests/TestRunner.p`, `src/cli/RunBuild.p`), se volvió a ejecutar la suite completa desde cero (`prowin.exe -b -p tests/TestRunner.p`, exit code `0`):

```
==================================================
INICIANDO SUITE DE PRUEBAS AUTOMATIZADAS TDD
Entorno OpenEdge PROVERSION: 12.8
Fecha y Hora: 07/09/2026 15:13:13
==================================================
Ejecutando todas las suites registradas...
--- Ejecutando test_rules_engine.p ---
  [PASS] Extension .p debe ser compilable
  [PASS] Extension .w debe ser compilable
  [PASS] Extension .cls debe ser compilable
  [PASS] Extension .i NO debe ser compilable
  [PASS] Extension .inc NO debe ser compilable
  [PASS] Extension .txt NO debe ser compilable
  [PASS] Extension .csv NO debe ser compilable
  [PASS] Extension .r NO debe ser compilable
  [PASS] Archivo en directorio raiz 'util/' NO debe ser compilable
  [PASS] Archivo con separador Windows 'util\' NO debe ser compilable
  [PASS] Archivo en subdirectorio 'src/util/' NO debe ser compilable
  [PASS] Archivo en subdirectorio 'src\util\' NO debe ser compilable
  [PASS] Archivo en 'modulo1/submodulo/util/' NO debe ser compilable
  [PASS] Directorio 'utilities' NO debe confundirse con 'util'
  [PASS] Nombre de archivo 'utilidad.p' NO debe ser excluido
  [PASS] Debe incluir opcion V6FRAME cuando el codigo contiene el token
  [PASS] NO debe incluir V6FRAME si el codigo no contiene el token
--- Fin test_rules_engine.p ---
--- Ejecutando test_propath_manager.p ---
  [PASS] Debe eliminar duplicados manteniendo el primer orden de aparicion
  [PASS] Debe recortar espacios en blanco y eliminar duplicados
  [PASS] Debe unificar separadores y reconocer duplicados con diferente diagonal
  [PASS] Debe detectar que existe al menos una ruta inexistente
  [PASS] La ruta inexistente debe reportarse en la lista de invalidas
  [PASS] Todas las rutas existentes deben validar en TRUE
  [PASS] No debe haber rutas invalidas reportadas
  [PASS] PROPATH efectivo estricto debe omitir rutas inexistentes y duplicados
--- Fin test_propath_manager.p ---
--- Ejecutando test_config_manager.p ---
  [PASS] La version objetivo por defecto debe ser OpenEdge 12.8
  [PASS] OpenEdge 12.8 debe ser soportado explicitamente
  [PASS] OpenEdge 11 debe ser permitido
  [PASS] OpenEdge 9 debe ser permitido por retrocompatibilidad
  [PASS] No debe limitarse a 9, 11 o 12; versiones futuras deben permitirse
  [PASS] Debe cargar catalogo CSV correctamente
  [PASS] Debe encontrar sistema VENTAS
  [PASS] Directorio fuente correcto para VENTAS
  [PASS] Directorio destino correcto para VENTAS
  [PASS] Propath extra correcto para VENTAS
  [PASS] Sistema no registrado no debe ser encontrado
  [PASS] Debe generar respaldo del catalogo CSV
  [PASS] Debe retornar la ruta del archivo .bak generado
  [PASS] El archivo de respaldo fisico debe existir en disco
  [PASS] Debe agregar o actualizar nuevo sistema en el catalogo
  [PASS] El sistema CONTABILIDAD debe existir tras ser agregado
  [PASS] Directorio fuente de CONTABILIDAD
--- Fin test_config_manager.p ---
--- Ejecutando test_build_logger.p ---
  [PASS] Build ID debe inicializarse correctamente
  [PASS] Total exitosos debe ser 1
  [PASS] Total fallidos debe ser 1
  [PASS] El archivo de reporte fisico debe existir en disco
  [PASS] El reporte debe incluir la version de OpenEdge (PROVERSION)
  [PASS] El reporte debe incluir el PROPATH efectivo
  [PASS] El reporte debe incluir el detalle del archivo fallido
  [PASS] El reporte debe registrar el codigo de error estructurado
--- Fin test_build_logger.p ---
--- Ejecutando test_build_engine.p ---
  [PASS] Programa valido debe compilar con exito
  [PASS] El archivo .r debe existir en el directorio de STAGING
  [PASS] El archivo .r debe haberse desplegado en el directorio FINAL
  [PASS] Programa con error de sintaxis debe reportar fallo en compilacion
  [PASS] El artefacto fallido NUNCA debe desplegarse en destino final
  [PASS] Programa en subdirectorio 'util' debe ser omitido
  [PASS] Programa en 'util' no debe ser desplegado
  [PASS] Archivo .i debe ser omitido
  [PASS] Archivo .i no debe ser desplegado
--- Fin test_build_engine.p ---
--- Ejecutando test_regression.p ---
  [PASS] compilador_legacy.w debe conservarse intacto en el workspace
  [PASS] compilador.w refactorizado debe estar presente
  [PASS] util/ptestv6frame.p debe excluirse por pertenecer a carpeta util
  [PASS] Ruta absoluta con /util/ debe ser excluida
  [PASS] Extension .p es compilable
  [PASS] Extension .w es compilable
  [PASS] Extension .cls es compilable para OE 12.8
  [PASS] PROPATH debe incluir src
  [PASS] PROPATH deterministico deduplicado
  [PASS] La version objetivo debe ser 12.8
--- Fin test_regression.p ---
==================================================
--------------------------------------------------
Resumen de Pruebas: Aserciones=69 Pasadas=69 Falladas=0
ESTADO FINAL: EXITO (Todas las pruebas pasaron)
--------------------------------------------------
==================================================
```

**69/69 aserciones pasan, y — por primera vez — el resumen y el `SESSION:EXIT-CODE` del propio `TestRunner.p` reflejan correctamente ese resultado** (antes, este mismo resumen habría dicho `0/0/0` sin importar el resultado real). Sin advertencia `HAS-RECORDS`.

Verificaciones adicionales tras el cambio:
- Ejecutar una sola suite vía `-param "tests/test_rules_engine.p"` agrega correctamente `Aserciones=17 Pasadas=17 Falladas=0`.
- Ejecutar un `test_*.p` de forma standalone (`prowin -b -p tests/test_rules_engine.p`, sin pasar por `TestRunner.p`) sigue funcionando sin cambios ni errores.

## Archivos modificados (resumen)

| Archivo | Cambio |
|---|---|
| `tests/TestRunner.p` | `QUIT n.` → `SESSION:EXIT-CODE = n. QUIT.`; nuevo procedimiento `runSuite` que ejecuta cada suite `PERSISTENT` y agrega sus totales reales. |
| `src/cli/RunBuild.p` | `QUIT n.` → `SESSION:EXIT-CODE = n. QUIT.` (4 ocurrencias). |
| `src/config/ConfigManager.i` | Se quitó `NO-ERROR` (inválido) de `INPUT FROM`; se reemplazó `HAS-RECORDS` sobre buffer por conteo explícito con `FOR EACH`. |
| `src/core/BuildEngine.i` | `COMPILE` ahora usa la ruta fuente resuelta a absoluta (`FILE-INFO:FULL-PATHNAME`) para que `SAVE INTO` guarde el `.r` de forma plana en staging, con fallo temprano si el archivo no se localiza. |
| `tests/Assert.i` | Nuevo procedimiento `getAssertTotals` (aditivo) para exponer los contadores de una suite a quien la invoque. |
| `CLAUDE.md` | Actualizado para reflejar la sintaxis correcta de `QUIT`/`SESSION:EXIT-CODE` y quitar la advertencia sobre el exit code no fiable (ya corregido). |

No hay control de versiones en este proyecto, así que estos cambios están directamente en el árbol de trabajo; no existe un commit que revertir.
