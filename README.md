# Compilador Progress OpenEdge 12.8

Motor de compilación desacoplado para programas Progress OpenEdge (ABL). Toma código fuente `.p`/`.w`/`.cls`, lo compila a un directorio de **staging** aislado y, solo si la compilación fue 100% exitosa, despliega los artefactos `.r` resultantes al directorio de destino final. Incluye una interfaz gráfica (AppBuilder) y un modo headless/CLI para builds desatendidos.

Este proyecto es una refactorización modular de un compilador GUI legacy (`compilador_legacy.w`, que se conserva intacto como referencia) hacia componentes procedurales independientes bajo `src/`.

## Requisitos

- Progress OpenEdge 12.8 (`prowin.exe` en Windows o `_progres` en modo batch puro).
- No requiere Node/npm ni otro tooling externo — todo el código es ABL.

## Uso

### Compilación headless (CLI)

```
prowin.exe -b -p src/cli/RunBuild.p -param "source=<dir_o_archivo>,deploy=<dir>,staging=<dir>,report=<ruta_log>"
```

O usando un sistema predefinido en el catálogo `compilador.csv`:

```
prowin.exe -b -p src/cli/RunBuild.p -param "system=<nombre_sistema>"
```

Parámetros soportados: `system`, `source`, `deploy`, `staging`, `report`.

### Interfaz gráfica

Abrir `compilador.w` desde Progress AppBuilder / OpenEdge Architect. `compila02.w` es la ventana de progreso/log en tiempo real que se acompaña.

## Estructura del proyecto

```
src/
  cli/RunBuild.p          Punto de entrada CLI headless
  core/BuildEngine.i       Orquestador del ciclo Build → Deploy
  core/PropathManager.i    Gestión determinística del PROPATH
  rules/RulesEngine.i      Reglas de inclusión/exclusión y opciones de compilación (V6FRAME)
  config/ConfigManager.i   Catálogo de sistemas (compilador.csv) y configuración
  logging/BuildLogger.i    Registro estructurado de resultados de build
compilador.w               GUI principal (AppBuilder), versión activa
compilador_legacy.w         GUI previa a la refactorización, conservada como referencia
compila02.w                 Ventana flotante de progreso/log
config/compiler_config.json Configuración de referencia (ver nota abajo)
tests/                       Suite de pruebas TDD propia en ABL
Documentacion/               Informes y documentación generada
```

> **Nota:** `config/compiler_config.json` describe la configuración deseada pero no es leído por ningún `.p`/`.i` del proyecto — los mismos valores están hardcodeados en `ConfigManager.i` y `RulesEngine.i`. Ver `CLAUDE.md` para más detalle.

## Ciclo de vida de compilación

1. **Filtrado por reglas** (`RulesEngine.i`): solo `.p`, `.w`, `.cls`; excluye cualquier ruta bajo un directorio `util/`.
2. **Detección de opciones especiales**: se analiza el código fuente en busca del token `V6FRAME` para aplicar la cláusula correspondiente en la compilación.
3. **Compilación aislada a staging**: `COMPILE ... SAVE INTO <staging>`, nunca directo al destino final.
4. **Despliegue condicional atómico**: el `.r` solo se copia al destino si la compilación fue 100% exitosa. Un build fallido nunca sobrescribe un artefacto bueno en producción.
5. **Registro estructurado** de cada resultado (`BuildLogger.i`), con reporte final persistible en disco.

## Pruebas

Arnés de pruebas TDD propio en ABL puro, sin framework externo.

Ejecutar toda la suite:

```
prowin.exe -b -p tests/TestRunner.p
```

Ejecutar una suite específica:

```
prowin.exe -b -p tests/TestRunner.p -param "tests/test_rules_engine.p"
```

El runner termina con código de salida `1` si hubo fallos y `0` si todo pasó (apto para CI). El estado y detalle de la última ejecución completa está documentado en `Documentacion/Informe_Ejecucion_Pruebas_2026-09-07.md`.

## Documentación adicional

- [`CLAUDE.md`](./CLAUDE.md): guía de arquitectura y convenciones del proyecto, pensada para trabajar sobre el código.
- [`Documentacion/`](./Documentacion): informes de ejecución y otra documentación generada.
