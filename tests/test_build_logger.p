/*------------------------------------------------------------------------
    File        : tests/test_build_logger.p
    Purpose     : Suite de pruebas unitarias (TDD) para BuildLogger.p
                  Valida registro estructurado de versión de OpenEdge,
                  PROPATH efectivo, archivos, errores con línea y mensaje,
                  y persistencia de reportes de build.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/logging/BuildLogger.i}

DEFINE VARIABLE vc_test_log   AS CHARACTER NO-UNDO INITIAL "tests/tmp_build_report.log".
DEFINE VARIABLE vi_total_ok   AS INTEGER   NO-UNDO.
DEFINE VARIABLE vi_total_fail AS INTEGER   NO-UNDO.
DEFINE VARIABLE vl_file_found AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_log_text   AS LONGCHAR  NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_build_logger.p ---" SKIP.

/* =================================================================== */
/* PRUEBA 1: Inicializacion del Build con PROVERSION y PROPATH         */
/* =================================================================== */

RUN initBuildLogger ("BUILD_TEST_001", "src,config,compilados", "compilados").

RUN getLoggerBuildId (OUTPUT vc_log_text).
RUN assertEqualsChar("BUILD_TEST_001", STRING(vc_log_text), "Build ID debe inicializarse correctamente").


/* =================================================================== */
/* PRUEBA 2: Registro de Compilacion Exitosa y Fallida                 */
/* =================================================================== */

/* Registro de exito */
RUN logFileResult ("src/ventas/pedido.p", 
                   "build/staging/pedido.r", 
                   "compilados/pedido.r", 
                   YES /* plSuccess */, 
                   ""  /* pcErrorMsg */, 
                   0   /* piErrNum */, 
                   0   /* piErrLine */).

/* Registro de fallo con mensaje de error estructurado */
RUN logFileResult ("src/ventas/error_sintaxis.p", 
                   "build/staging/error_sintaxis.r", 
                   "compilados/error_sintaxis.r", 
                   NO /* plSuccess */, 
                   "** Expresion desconocida o fin inesperado de linea", 
                   247 /* piErrNum */, 
                   12  /* piErrLine */).

RUN getBuildTotals (OUTPUT vi_total_ok, OUTPUT vi_total_fail).
RUN assertEqualsInt(1, vi_total_ok, "Total exitosos debe ser 1").
RUN assertEqualsInt(1, vi_total_fail, "Total fallidos debe ser 1").


/* =================================================================== */
/* PRUEBA 3: Persistencia del Reporte Estructurado en Disco            */
/* =================================================================== */

RUN writeBuildReport (vc_test_log).

FILE-INFO:FILE-NAME = vc_test_log.
RUN assertTrue(FILE-INFO:FULL-PATHNAME <> ?, "El archivo de reporte fisico debe existir en disco").

/* Verificar que el contenido incluye PROVERSION y PROPATH */
COPY-LOB FROM FILE vc_test_log TO vc_log_text.

RUN assertTrue(INDEX(STRING(vc_log_text), "PROVERSION") > 0, 
               "El reporte debe incluir la version de OpenEdge (PROVERSION)").
RUN assertTrue(INDEX(STRING(vc_log_text), "PROPATH") > 0, 
               "El reporte debe incluir el PROPATH efectivo").
RUN assertTrue(INDEX(STRING(vc_log_text), "error_sintaxis.p") > 0, 
               "El reporte debe incluir el detalle del archivo fallido").
RUN assertTrue(INDEX(STRING(vc_log_text), "247") > 0, 
               "El reporte debe registrar el codigo de error estructurado").

/* Limpieza de archivo temporal */
OS-DELETE VALUE(vc_test_log).

PUT UNFORMATTED "--- Fin test_build_logger.p ---" SKIP.
