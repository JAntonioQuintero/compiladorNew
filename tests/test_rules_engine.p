/*------------------------------------------------------------------------
    File        : tests/test_rules_engine.p
    Purpose     : Suite de pruebas unitarias (TDD) para RulesEngine.p
                  Valida extensiones permitidas (.p, .w, .cls), exclusión
                  de subdirectorios 'util' y regla V6FRAME.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/rules/RulesEngine.i}

DEFINE VARIABLE vl_compilable AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_reason     AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_options    AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_notes      AS CHARACTER NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_rules_engine.p ---" SKIP.

/* =================================================================== */
/* PRUEBA 1: Extensiones Permitidas (.p, .w, .cls) y No Permitidas    */
/* =================================================================== */

/* Casos validos */

RUN isCompilable ("src/ventas/pedido.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .p debe ser compilable").

RUN isCompilable ("src/ventas/m_pedido.w", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .w debe ser compilable").

RUN isCompilable ("src/services/OrderService.cls", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .cls debe ser compilable").

/* Casos invalidos */
RUN isCompilable ("src/includes/definitions.i", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Extension .i NO debe ser compilable").

RUN isCompilable ("src/includes/header.inc", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Extension .inc NO debe ser compilable").

RUN isCompilable ("docs/leeme.txt", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Extension .txt NO debe ser compilable").

RUN isCompilable ("config/compilador.csv", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Extension .csv NO debe ser compilable").

RUN isCompilable ("compilados/pedido.r", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Extension .r NO debe ser compilable").


/* =================================================================== */
/* PRUEBA 2: Exclusion Obligatoria de Subdirectorios 'util'            */
/* =================================================================== */

RUN isCompilable ("util/ptestv6frame.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Archivo en directorio raiz 'util/' NO debe ser compilable").

RUN isCompilable ("util\ptestv6frame.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Archivo con separador Windows 'util\' NO debe ser compilable").

RUN isCompilable ("src/util/helper.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Archivo en subdirectorio 'src/util/' NO debe ser compilable").

RUN isCompilable ("src\util\helper.w", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Archivo en subdirectorio 'src\util\' NO debe ser compilable").

RUN isCompilable ("modulo1/submodulo/util/Tool.cls", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Archivo en 'modulo1/submodulo/util/' NO debe ser compilable").

/* Casos con 'util' como parte de otra palabra (deben permitirse) */
RUN isCompilable ("src/utilities/helper.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Directorio 'utilities' NO debe confundirse con 'util'").

RUN isCompilable ("src/ventas/utilidad.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Nombre de archivo 'utilidad.p' NO debe ser excluido").


/* =================================================================== */
/* PRUEBA 3: Centralizacion de Regla V6FRAME                            */
/* =================================================================== */

/* Creamos fixtures temporales para pruebas de contenido */
DEFINE VARIABLE vc_tmp_v6    AS CHARACTER NO-UNDO INITIAL "tests/tmp_v6frame.p".
DEFINE VARIABLE vc_tmp_nov6  AS CHARACTER NO-UNDO INITIAL "tests/tmp_normal.p".

OUTPUT TO VALUE(vc_tmp_v6).
PUT UNFORMATTED "/* Programa con frame tradicional V6FRAME */" SKIP.
PUT UNFORMATTED "DEFINE FRAME f1 WITH V6FRAME." SKIP.
OUTPUT CLOSE.

OUTPUT TO VALUE(vc_tmp_nov6).
PUT UNFORMATTED "/* Programa estandar sin frames obsoletos */" SKIP.
PUT UNFORMATTED "MESSAGE 'Hola OpenEdge 12.8' VIEW-AS ALERT-BOX." SKIP.
OUTPUT CLOSE.

RUN getCompileOptions (vc_tmp_v6, OUTPUT vc_options, OUTPUT vc_notes).
RUN assertTrue(LOOKUP("V6FRAME", vc_options, " ") > 0, "Debe incluir opcion V6FRAME cuando el codigo contiene el token").

RUN getCompileOptions (vc_tmp_nov6, OUTPUT vc_options, OUTPUT vc_notes).
RUN assertFalse(LOOKUP("V6FRAME", vc_options, " ") > 0, "NO debe incluir V6FRAME si el codigo no contiene el token").

/* Limpieza de fixtures temporales */
OS-DELETE VALUE(vc_tmp_v6).
OS-DELETE VALUE(vc_tmp_nov6).

PUT UNFORMATTED "--- Fin test_rules_engine.p ---" SKIP.
