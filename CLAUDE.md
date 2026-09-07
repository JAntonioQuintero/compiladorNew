# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es esto

Compilador headless/GUI para programas Progress OpenEdge 12.8 (ABL). Toma código fuente `.p`/`.w`/`.cls`, lo compila a un directorio de **staging** aislado y, solo si la compilación fue 100% exitosa, despliega los artefactos `.r` resultantes al directorio de destino final (`compilados/`). El proyecto es una refactorización desacoplada de un compilador GUI legacy (`compilador_legacy.w`) hacia módulos procedurales independientes bajo `src/`, más un punto de entrada CLI headless.

No es un repo Git (`Is a git repository: false`) — no asumas historial ni ramas disponibles.

## Runtime y comandos

Todo el código es Progress OpenEdge ABL (`.p`, `.w`, `.i`, `.cls`). No hay Node/npm/build tooling estándar; la "compilación" y las "pruebas" se ejecutan invocando al runtime de OpenEdge (`prowin.exe` en Windows o `_progres` en modo batch puro).

**Ejecutar el compilador headless (CLI):**
```
prowin.exe -b -p src/cli/RunBuild.p -param "source=<dir_o_archivo>,deploy=<dir>,staging=<dir>,report=<ruta_log>"
```
o usando un sistema predefinido en el catálogo `compilador.csv`:
```
prowin.exe -b -p src/cli/RunBuild.p -param "system=<nombre_sistema>"
```
Parámetros clave=valor soportados: `system`, `source`, `deploy`, `staging`, `report`.

**Ejecutar toda la suite de pruebas:**
```
prowin.exe -b -p tests/TestRunner.p
```

**Ejecutar una suite de pruebas específica:**
```
prowin.exe -b -p tests/TestRunner.p -param "tests/test_rules_engine.p"
```
`TestRunner.p` ejecuta las suites registradas explícitamente en su propio código (ver `tests/TestRunner.p`) cuando no se pasa `-param`; para correr solo un archivo, pasar su ruta como parámetro. El runner fija `SESSION:EXIT-CODE = 1` si hubo fallos y `0` si todo pasó antes de `QUIT` (`QUIT` en ABL no acepta un código como parámetro). Cada suite se ejecuta vía un procedimiento interno `runSuite` que la corre con `RUN ... PERSISTENT` y lee sus totales reales con `RUN getAssertTotals IN <handle>` antes de liberarla — necesario porque cada `test_*.p` incluye su propia copia privada de `tests/Assert.i` y sus contadores no se comparten de otro modo; sin este mecanismo el resumen final y el exit code siempre reportaban éxito (bug real, detectado y corregido — detalle completo en `Documentacion/Informe_Ejecucion_Pruebas_2026-09-07.md`). El exit code de `TestRunner.p` ya es fiable como gate de CI.

## Arquitectura

### Ciclo de vida Build → Deploy (núcleo del sistema)

Implementado en `src/core/BuildEngine.i` (`compileSingleFile`, `runFullBuild`). El flujo es siempre:

1. **Filtrado por reglas** (`src/rules/RulesEngine.i` → `isCompilable`): solo `.p`, `.w`, `.cls`; excluye estrictamente cualquier ruta que empiece con o contenga `util/` (o `\util\`) como segmento de directorio — pero no como substring de otro nombre (`utilities/` sí se permite).
2. **Detección de opciones especiales** (`getCompileOptions`): lee el contenido del fuente vía `COPY-LOB` buscando el token `V6FRAME`; si aparece, se compila con la cláusula `V6FRAME` (reemplaza al antiguo `util/ptestv6frame.p` legacy — ver abajo).
3. **Compilación aislada a staging**: `COMPILE ... SAVE INTO <staging>`. Nunca se compila directo al destino final.
4. **Despliegue condicional atómico**: solo si `COMPILER:ERROR` y `ERROR-STATUS:ERROR` son ambos falsos, se hace `OS-COPY` del `.r` de staging al directorio de despliegue. Si falla la compilación, el artefacto **nunca** se copia a destino — principio "restrictivo" explícito en el código.
5. **Registro estructurado** de cada resultado vía `logFileResult` en `src/logging/BuildLogger.i`.

Cuando modifiques este flujo, preserva el orden y la garantía de que un despliegue fallido/parcial jamás sobrescribe un `.r` bueno en destino.

### Módulos desacoplados (`src/`)

Cada `.i` es un include con procedimientos internos (no hay OO/clases en el core); cada `.p` es un punto de entrada mínimo que hace `{...}` include de su `.i` correspondiente y sirve como stub ejecutable/persistente. Este patrón `.p`/`.i` es idéntico en los cuatro módulos (`RulesEngine`, `PropathManager`, `ConfigManager`, `BuildLogger`): el `.p` no añade lógica propia, solo el include y un `MESSAGE ... VIEW-AS ALERT-BOX` de ayuda si se ejecuta standalone sin ser persistente. La lógica real vive siempre en el `.i`. Al añadir un módulo nuevo, replica este patrón en vez de meter lógica directamente en el `.p`.

- **`src/rules/RulesEngine.i`** — única fuente de verdad para qué archivos se compilan (`isCompilable`) y qué opciones de compilación aplican (`getCompileOptions`, regla V6FRAME).
- **`src/core/PropathManager.i`** — normalización, deduplicación (preservando orden de precedencia) y validación en disco de entradas de PROPATH (`buildDeterministicPropath`, `validatePropathEntries`, `getEffectivePropath`).
- **`src/config/ConfigManager.i`** — carga/parseo del catálogo CSV de sistemas (`compilador.csv`, temp-table `tt_sistema`), búsqueda de configuración por sistema (`findSystemConfig`, sustituto de la antigua `BuscaSistema`), y escritura con respaldo automático con timestamp (`backupCatalog` + `saveOrUpdateSystem`) antes de cualquier modificación del catálogo.
- **`src/logging/BuildLogger.i`** — temp-table `tt_build_entry` con el detalle de cada archivo compilado; soporta un "listener" gráfico opcional (`setLogListener`/`CargaMensaje`) para emitir progreso en tiempo real hacia `compila02.w`, y `writeBuildReport` para persistir un reporte de texto estructurado.
- **`src/core/BuildEngine.i`** — orquestador; ver arriba.
- **`src/cli/RunBuild.p`** — único punto de entrada CLI headless. Parsea `SESSION:PARAMETER` como pares `clave=valor` separados por coma. Si recibe `system=`, resuelve `source`/`deploy`/PROPATH extra desde el catálogo vía `ConfigManager`. Si `source` apunta a un archivo individual (contiene `.`), compila solo ese archivo; si es un directorio, el escaneo/listado de archivos elegibles queda delegado a la integración GUI (marcado como pendiente en el código, ver comentario `REQUIERE_VALIDACION_OE128`).

### Interfaz gráfica (AppBuilder `.w`)

- **`compilador.w`** — ventana GUI principal, generada con Progress AppBuilder (UIB), ~3100 líneas. Es la versión **activa/refactorizada**: incluye los módulos de `src/` (ver bloque de includes cerca de la línea 40) y usa `RulesEngine`/`ConfigManager` en vez de lógica acoplada. Trabaja con la versión de OpenEdge 12.8 codificada explícitamente (`PROVERSION BEGINS "12"`).
- **`compilador_legacy.w`** — versión previa a la refactorización, sin los includes de `src/`, con lógica de reglas y versión (9/11) acoplada inline, encoding roto (mojibake en tildes/ñ) y mensajes distintos. Se conserva como referencia histórica/rollback; **no editar ni eliminar** — `tests/test_regression.p` verifica en runtime (`FILE-INFO`) que tanto `compilador_legacy.w` como `compilador.w` sigan existiendo en el workspace, así que borrar o mover el legacy rompe la suite de regresión. Los cambios de producto van en `compilador.w`.
- **`compila02.w`** — ventana flotante secundaria de progreso/log; recibe mensajes en tiempo real vía el procedimiento interno `CargaMensaje`, que es invocado por `BuildLogger.i:logMessage` cuando hay un listener registrado (`setLogListener`).

Al tocar cualquier `.w`, ten en cuenta que fueron generados por Progress AppBuilder: contienen bloques `&ANALYZE-SUSPEND/&ANALYZE-RESUME` y secciones `_UIB-*` que el AppBuilder usa para regenerar el diseño visual — no los reformatees ni reordenes manualmente, edita dentro de las secciones de código de usuario.

### Legacy suelto

- **`ptestv6frame.p`** (raíz, fuera de `util/` pese al nombre) — implementación original standalone de la detección V6FRAME que `RulesEngine.i:getCompileOptions` reemplaza. Se mantiene solo como referencia; la lógica viva vive en `RulesEngine.i`.

### Configuración

- **`config/compiler_config.json`** — describe la configuración global deseada (versión objetivo `12.8`, extensiones permitidas, directorios excluidos, staging/deploy/logs, flags `detectV6Frame`/`requireExplicitOe128`), **pero ningún `.p`/`.i` del repo lo lee** (no hay `READ-JSON` ni parsing de JSON en `src/`). Es documentación/intención, no configuración activa: los mismos valores están hardcodeados por separado en el código (`gc_target_version = "12.8"` en `ConfigManager.i`, extensiones `.p/.w/.cls` y exclusión de `util` en `RulesEngine.i`). Si cambias este JSON esperando que afecte el comportamiento del compilador, no pasará nada — hay que tocar el `.i` correspondiente. No asumas que está conectado sin verificarlo de nuevo si el código evoluciona.
- **`compilador.csv`** (en la raíz del proyecto o `config/compilador.default.csv` como fallback) — catálogo de "sistemas" con columnas `Sistema,DirectorioFuente,DirectorioCompilados,PropathExtra,Activo`, gestionado por `ConfigManager.i`. Ninguno de los dos existe en el repo por defecto; se generan/actualizan en runtime vía `saveOrUpdateSystem` (con respaldo `.bak.<timestamp>` previo obligatorio a cada escritura).
- `isVersionSupported` (`ConfigManager.i`) siempre devuelve `YES` para cualquier valor no vacío — es deliberado (los tests lo afirman explícitamente para 9.x, 11.x, 12.8 y versiones futuras como 13.0), no un bug ni una validación incompleta.

### Pruebas (`tests/`)

Arnés TDD propio en ABL puro, sin framework externo:

- **`tests/Assert.i`** — aserciones (`assertTrue`, `assertFalse`, `assertEqualsChar`, `assertEqualsInt`, `assertEqualsLog`) y contadores globales (`gi_tests_run/passed/failed`), más `printTestSummary`.
- **`tests/TestRunner.p`** — punto de entrada; ejecuta una suite específica (parámetro) o todas las registradas inline, imprime resumen y sale con código de proceso acorde (`QUIT 1` si hubo fallos).
- Cada `test_*.p` incluye `{tests/Assert.i}` y el/los `.i` bajo prueba, y genera/limpia fixtures temporales **directamente en `tests/`** con `OUTPUT TO`/`OS-CREATE-DIR` al inicio y `OS-DELETE` al final (no hay carpeta `fixtures/` separada ni mocks — todo es I/O real a disco). Ver `tests/test_rules_engine.p` o `tests/test_build_engine.p` como patrón de referencia.
- Las suites asumen que el proceso se ejecuta con el **directorio de trabajo en la raíz del repo**: usan rutas relativas fijas como `"src"`, `"config"`, `"tests"`, `"Documentacion"` (p. ej. `tests/test_propath_manager.p` y `tests/test_regression.p` validan PROPATH contra la existencia real de esas carpetas). Ejecutar `prowin.exe`/`_progres` desde otro directorio hará fallar aserciones de existencia de rutas, no solo errores de "archivo no encontrado".
- `test_build_engine.p` y `test_config_manager.p` limpian sus propios fixtures pero **no** eliminan los directorios que crean (`tests/staging_test`, `tests/deploy_test`, `tests/util/`) — quedan en disco entre corridas; no es un bug a arreglar por iniciativa propia, pero ten en cuenta que reaparecen tras cada ejecución.
- `tests/test_regression.p` es la suite que ancla comportamiento legado: exige que `compilador_legacy.w` y `compilador.w` coexistan, que el PROPATH determinístico no inserte rutas absolutas, y que la versión objetivo siga siendo `"12.8"` — trátala como el primer lugar a revisar si un cambio "rompe algo que no debería".
- Al añadir una suite nueva, regístrala también en `tests/TestRunner.p` (bloque `IF SEARCH(...) THEN RUN ...`).

## Convenciones de código específicas de este repo

- Prefijos de variables tipo Hungarian notation consistentes en todo el código ABL: `vc_`/`vc-` (character), `vi_`/`vi-` (integer), `vl_`/`vl-` (logical), `pc`/`pi`/`pl` para parámetros, `gc_`/`gi_`/`gl_`/`gh_` para variables globales/de módulo. Los módulos nuevos en `src/` usan guión bajo (`vc_source`); el código legacy en `.w` usa guión medio (`vc-dirbc`). Sigue la convención del archivo que estés tocando.
- Todas las rutas se normalizan a `/` internamente (`REPLACE(x, "\", "/")`) antes de comparar o construir paths, independientemente de que el sistema sea Windows.
- Los comentarios `REQUIERE_VALIDACION_OE128` marcan puntos del código pendientes de validación explícita contra el comportamiento real de OpenEdge 12.8 (p. ej. semántica de `V6FRAME`, `OS-DIR` con `.cls`). Trátalos como TODOs de alta prioridad, no los borres al tocar código cercano sin resolver la validación.
- Los procedimientos de negocio siempre devuelven un par `(plSuccess/plXxx AS LOGICAL, pcMessage AS CHARACTER)` como últimos `OUTPUT PARAMETER`, nunca lanzan errores no controlados hacia el llamador — sigue este patrón en código nuevo.
