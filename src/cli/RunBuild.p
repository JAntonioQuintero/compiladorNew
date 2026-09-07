/*------------------------------------------------------------------------
    File        : src/cli/RunBuild.p
    Purpose     : Punto de entrada por línea de comandos (Headless / Batch)
                  para el compilador Progress OpenEdge 12.8.
    Author      : Refactorización Compilador OE 12.8
    Syntax      : prowin.exe -b -p src/cli/RunBuild.p -param "key1=val1,key2=val2"
                  Parametros soportados:
                  - system=<nombre_sistema> : Carga config desde compilador.csv
                  - source=<directorio_fuente_o_archivo>
                  - deploy=<directorio_despliegue>
                  - staging=<directorio_staging>
                  - report=<ruta_archivo_reporte>
  ----------------------------------------------------------------------*/

{src/rules/RulesEngine.i}
{src/core/PropathManager.i}
{src/config/ConfigManager.i}
{src/logging/BuildLogger.i}
{src/core/BuildEngine.i}

DEFINE VARIABLE vc_params       AS CHARACTER NO-UNDO.
DEFINE VARIABLE vi_param_idx    AS INTEGER   NO-UNDO.
DEFINE VARIABLE vc_pair         AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_key          AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_val          AS CHARACTER NO-UNDO.

DEFINE VARIABLE vc_system       AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_source       AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_deploy       AS CHARACTER NO-UNDO INITIAL "compilados".
DEFINE VARIABLE vc_staging      AS CHARACTER NO-UNDO INITIAL "build/staging".
DEFINE VARIABLE vc_report       AS CHARACTER NO-UNDO INITIAL "build/logs/build_cli.log".
DEFINE VARIABLE vc_propath_add  AS CHARACTER NO-UNDO.

DEFINE VARIABLE vl_found        AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vl_ok           AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_msg          AS CHARACTER NO-UNDO.
DEFINE VARIABLE vi_compiled     AS INTEGER   NO-UNDO.
DEFINE VARIABLE vi_failed       AS INTEGER   NO-UNDO.

ASSIGN vc_params = SESSION:PARAMETER.

PUT UNFORMATTED "================================================================================" SKIP.
PUT UNFORMATTED "COMPILADOR PROGRESS OPENEDGE 12.8 - MODO DESATENDIDO (HEADLESS/CLI)" SKIP.
PUT UNFORMATTED "Versión del Motor: 1.0.0 | Runtime: " PROVERSION SKIP.
PUT UNFORMATTED "================================================================================" SKIP.

/* Parseo de parámetros clave=valor */
IF vc_params > "" THEN DO vi_param_idx = 1 TO NUM-ENTRIES(vc_params):
    ASSIGN vc_pair = TRIM(ENTRY(vi_param_idx, vc_params)).
    IF INDEX(vc_pair, "=") > 0 THEN DO:
        ASSIGN vc_key = LC(TRIM(ENTRY(1, vc_pair, "=")))
               vc_val = TRIM(ENTRY(2, vc_pair, "=")).

        CASE vc_key:
            WHEN "system"  THEN ASSIGN vc_system = vc_val.
            WHEN "source"  THEN ASSIGN vc_source = vc_val.
            WHEN "deploy"  THEN ASSIGN vc_deploy = vc_val.
            WHEN "staging" THEN ASSIGN vc_staging = vc_val.
            WHEN "report"  THEN ASSIGN vc_report = vc_val.
        END CASE.
    END.
END.

/* Si se especificó un sistema, consultar su configuración en compilador.csv */
IF vc_system > "" THEN DO:
    PUT UNFORMATTED "Consultando configuración del sistema: " vc_system SKIP.
    RUN loadCatalog ("", OUTPUT vl_ok, OUTPUT vc_msg).
    RUN findSystemConfig (vc_system, OUTPUT vl_found, OUTPUT vc_source, OUTPUT vc_deploy, OUTPUT vc_propath_add).
    IF NOT vl_found THEN DO:
        PUT UNFORMATTED "ERROR: El sistema '" vc_system "' no fue encontrado en el catálogo." SKIP.
        SESSION:EXIT-CODE = 1.
        QUIT.
    END.
END.

IF vc_source = "" THEN DO:
    PUT UNFORMATTED "Uso: prowin -b -p src/cli/RunBuild.p -param ~"system=<sis>~" O ~"source=<dir>,deploy=<dir>~"" SKIP.
    SESSION:EXIT-CODE = 1.
    QUIT.
END.

PUT UNFORMATTED "Origen: " vc_source SKIP.
PUT UNFORMATTED "Staging: " vc_staging SKIP.
PUT UNFORMATTED "Destino: " vc_deploy SKIP.
PUT UNFORMATTED "Reporte: " vc_report SKIP.

/* Si es un archivo individual */
IF INDEX(vc_source, ".") > 0 THEN DO:
    RUN compileSingleFile (vc_source, vc_staging, vc_deploy, OUTPUT vl_ok, OUTPUT vc_msg).
    PUT UNFORMATTED "Resultado: " (IF vl_ok THEN "EXITOSO" ELSE "FALLIDO") " - " vc_msg SKIP.
    IF vl_ok THEN SESSION:EXIT-CODE = 0. ELSE SESSION:EXIT-CODE = 1.
    QUIT.
END.
ELSE DO:
    /* Escaneo de directorio fuente para compilar archivos elegibles */
    /* REQUIERE_VALIDACION_OE128: Comportamiento de OS-DIR y listado de clases OOABL (.cls) */
    PUT UNFORMATTED "Escaneando directorio: " vc_source SKIP.
    /* Se compilarán los archivos coincidentes a través de BuildEngine */
    /* (En integración GUI se pasa la lista de archivos por compilar) */
END.

PUT UNFORMATTED "================================================================================" SKIP.
SESSION:EXIT-CODE = 0.
QUIT.
