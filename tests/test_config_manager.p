/*------------------------------------------------------------------------
    File        : tests/test_config_manager.p
    Purpose     : Suite de pruebas unitarias (TDD) para ConfigManager.p
                  Valida lectura de configuración externa, sustitución de
                  BuscaSistema sin límites fijos de versión 9/11, soporte
                  explícito de OE 12.8, lectura, respaldo preventivo y
                  escritura segura de compilador.csv.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/config/ConfigManager.i}

DEFINE VARIABLE vc_csv_test    AS CHARACTER NO-UNDO INITIAL "tests/tmp_compilador.csv".
DEFINE VARIABLE vc_csv_bak     AS CHARACTER NO-UNDO.
DEFINE VARIABLE vl_found       AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_fuente      AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_destino     AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_extrapp     AS CHARACTER NO-UNDO.
DEFINE VARIABLE vl_success     AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_msg         AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_target_ver  AS CHARACTER NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_config_manager.p ---" SKIP.

/* =================================================================== */
/* PRUEBA 1: Soporte de Version OpenEdge 12.8 y No Limitar a 9, 11 o 12*/
/* =================================================================== */

RUN getTargetOpenEdgeVersion (OUTPUT vc_target_ver).
RUN assertEqualsChar("12.8", vc_target_ver, "La version objetivo por defecto debe ser OpenEdge 12.8").

/* Validacion de version generica (no debe rechazar 12.8 ni versiones superiores) */
RUN isVersionSupported ("12.8", OUTPUT vl_found).
RUN assertTrue(vl_found, "OpenEdge 12.8 debe ser soportado explicitamente").

RUN isVersionSupported ("11.7", OUTPUT vl_found).
RUN assertTrue(vl_found, "OpenEdge 11 debe ser permitido").

RUN isVersionSupported ("9.1D", OUTPUT vl_found).
RUN assertTrue(vl_found, "OpenEdge 9 debe ser permitido por retrocompatibilidad").

RUN isVersionSupported ("13.0", OUTPUT vl_found).
RUN assertTrue(vl_found, "No debe limitarse a 9, 11 o 12; versiones futuras deben permitirse").


/* =================================================================== */
/* PRUEBA 2: Sustitucion Desacoplada de BuscaSistema                   */
/* =================================================================== */

/* Creamos un archivo CSV de prueba */
OUTPUT TO VALUE(vc_csv_test).
PUT UNFORMATTED "Sistema,DirectorioFuente,DirectorioCompilados,PropathExtra,Activo" SKIP.
PUT UNFORMATTED "VENTAS,src/ventas,compilados/ventas,src/comun,SI" SKIP.
PUT UNFORMATTED "FACTURAS,src/facturas,compilados/facturas,,SI" SKIP.
OUTPUT CLOSE.

RUN loadCatalog (vc_csv_test, OUTPUT vl_success, OUTPUT vc_msg).
RUN assertTrue(vl_success, "Debe cargar catalogo CSV correctamente").

/* Buscar sistema existente */
RUN findSystemConfig ("VENTAS", OUTPUT vl_found, OUTPUT vc_fuente, OUTPUT vc_destino, OUTPUT vc_extrapp).
RUN assertTrue(vl_found, "Debe encontrar sistema VENTAS").
RUN assertEqualsChar("src/ventas", vc_fuente, "Directorio fuente correcto para VENTAS").
RUN assertEqualsChar("compilados/ventas", vc_destino, "Directorio destino correcto para VENTAS").
RUN assertEqualsChar("src/comun", vc_extrapp, "Propath extra correcto para VENTAS").

/* Buscar sistema inexistente */
RUN findSystemConfig ("NOMINA_NO_EXISTE", OUTPUT vl_found, OUTPUT vc_fuente, OUTPUT vc_destino, OUTPUT vc_extrapp).
RUN assertFalse(vl_found, "Sistema no registrado no debe ser encontrado").


/* =================================================================== */
/* PRUEBA 3: Respaldo Automatico (.bak) Preventivo Antes de Actualizar */
/* =================================================================== */

RUN backupCatalog (vc_csv_test, OUTPUT vc_csv_bak, OUTPUT vl_success, OUTPUT vc_msg).
RUN assertTrue(vl_success, "Debe generar respaldo del catalogo CSV").
RUN assertTrue(vc_csv_bak > "", "Debe retornar la ruta del archivo .bak generado").

/* Verificar que el archivo de respaldo existe fisicamente */
FILE-INFO:FILE-NAME = vc_csv_bak.
RUN assertTrue(FILE-INFO:FULL-PATHNAME <> ?, "El archivo de respaldo fisico debe existir en disco").


/* =================================================================== */
/* PRUEBA 4: Sincronizacion / Actualizacion Segura de Sistema          */
/* =================================================================== */

RUN saveOrUpdateSystem (vc_csv_test, "CONTABILIDAD", "src/contab", "compilados/contab", "", "SI",
                        OUTPUT vl_success, OUTPUT vc_msg).
RUN assertTrue(vl_success, "Debe agregar o actualizar nuevo sistema en el catalogo").

/* Verificar que el nuevo sistema ya se encuentra disponible */
RUN findSystemConfig ("CONTABILIDAD", OUTPUT vl_found, OUTPUT vc_fuente, OUTPUT vc_destino, OUTPUT vc_extrapp).
RUN assertTrue(vl_found, "El sistema CONTABILIDAD debe existir tras ser agregado").
RUN assertEqualsChar("src/contab", vc_fuente, "Directorio fuente de CONTABILIDAD").

/* Limpieza de fixtures temporales */
OS-DELETE VALUE(vc_csv_test).
IF vc_csv_bak > "" THEN OS-DELETE VALUE(vc_csv_bak).

PUT UNFORMATTED "--- Fin test_config_manager.p ---" SKIP.
