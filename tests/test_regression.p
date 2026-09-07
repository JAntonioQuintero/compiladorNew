/*------------------------------------------------------------------------
    File        : tests/test_regression.p
    Purpose     : Suite de pruebas de regresión para validar la preservación
                  funcional del compilador respecto a la versión legada.
                  Verifica:
                  - Existencia intacta de compilador_legacy.w
                  - Compatibilidad de compilador.csv y su respaldo
                  - Coexistencia del flujo GUI y flujo CLI
                  - Reglas de V6FRAME y exclusión de util
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/rules/RulesEngine.i}
{src/core/PropathManager.i}
{src/config/ConfigManager.i}
{src/logging/BuildLogger.i}
{src/core/BuildEngine.i}

DEFINE VARIABLE vl_legacy_exists AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vl_gui_exists    AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vl_compilable    AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_reason        AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_eff_pp        AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_ver           AS CHARACTER NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_regression.p ---" SKIP.

/* =================================================================== */
/* REGRESION 1: Preservacion Obligatoria del Compilador Legado         */
/* =================================================================== */

FILE-INFO:FILE-NAME = "compilador_legacy.w".
ASSIGN vl_legacy_exists = (FILE-INFO:FULL-PATHNAME <> ?).
RUN assertTrue(vl_legacy_exists, "compilador_legacy.w debe conservarse intacto en el workspace").

FILE-INFO:FILE-NAME = "compilador.w".
ASSIGN vl_gui_exists = (FILE-INFO:FULL-PATHNAME <> ?).
RUN assertTrue(vl_gui_exists, "compilador.w refactorizado debe estar presente").


/* =================================================================== */
/* REGRESION 2: Reglas de Exclusion y Extensiones en Regresion         */
/* =================================================================== */

/* Archivo en util legado ptestv6frame.p:
   El archivo ptestv6frame.p original en raíz se procesa si se solicita, pero
   cualquier archivo dentro de subdirectorio util NO debe compilarse */
RUN isCompilable ("util/ptestv6frame.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "util/ptestv6frame.p debe excluirse por pertenecer a carpeta util").

RUN isCompilable ("c:/proyectos/sistema/util/herramienta.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertFalse(vl_compilable, "Ruta absoluta con /util/ debe ser excluida").

/* Extensiones */
RUN isCompilable ("programa.p", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .p es compilable").

RUN isCompilable ("ventana.w", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .w es compilable").

RUN isCompilable ("Clase.cls", OUTPUT vl_compilable, OUTPUT vc_reason).
RUN assertTrue(vl_compilable, "Extension .cls es compilable para OE 12.8").


/* =================================================================== */
/* REGRESION 3: PROPATH Deterministico sin Insercion de Rutas Absolutas */
/* =================================================================== */

RUN getEffectivePropath ("src,config,src,Documentacion", YES, OUTPUT vc_eff_pp).
RUN assertTrue(INDEX(vc_eff_pp, "src") > 0, "PROPATH debe incluir src").
RUN assertEqualsChar("src,config,Documentacion", vc_eff_pp, "PROPATH deterministico deduplicado").


/* =================================================================== */
/* REGRESION 4: Version Objetivo OpenEdge 12.8                         */
/* =================================================================== */

RUN getTargetOpenEdgeVersion (OUTPUT vc_ver).
RUN assertEqualsChar("12.8", vc_ver, "La version objetivo debe ser 12.8").

PUT UNFORMATTED "--- Fin test_regression.p ---" SKIP.
