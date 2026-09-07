/*------------------------------------------------------------------------
    File        : tests/test_build_engine.p
    Purpose     : Suite de pruebas unitarias (TDD) para BuildEngine.p
                  Valida el ciclo de vida de compilación:
                  - Compilación a directorio temporal de staging
                  - Separación estricta de Build y Deploy
                  - Despliegue de artefactos .r solo en compilación exitosa
                  - Bloqueo total de despliegue si la compilación falla
                  - Exclusión de utilitarios y extensiones no soportadas
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/rules/RulesEngine.i}
{src/core/PropathManager.i}
{src/logging/BuildLogger.i}
{src/core/BuildEngine.i}

DEFINE VARIABLE vc_staging_dir AS CHARACTER NO-UNDO INITIAL "tests/staging_test".
DEFINE VARIABLE vc_deploy_dir  AS CHARACTER NO-UNDO INITIAL "tests/deploy_test".
DEFINE VARIABLE vc_valid_p     AS CHARACTER NO-UNDO INITIAL "tests/test_prog_valid.p".
DEFINE VARIABLE vc_invalid_p   AS CHARACTER NO-UNDO INITIAL "tests/test_prog_invalid.p".
DEFINE VARIABLE vc_util_p      AS CHARACTER NO-UNDO INITIAL "tests/util/test_prog_util.p".
DEFINE VARIABLE vc_include_i   AS CHARACTER NO-UNDO INITIAL "tests/test_include.i".

DEFINE VARIABLE vl_build_ok    AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_build_msg   AS CHARACTER NO-UNDO.
DEFINE VARIABLE vi_success     AS INTEGER   NO-UNDO.
DEFINE VARIABLE vi_failed      AS INTEGER   NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_build_engine.p ---" SKIP.

/* =================================================================== */
/* PREPARACION DE ESCENARIOS Y FIXTURES DE PRUEBA                      */
/* =================================================================== */

/* 1. Crear directorios de prueba si no existen */
OS-CREATE-DIR VALUE(vc_staging_dir).
OS-CREATE-DIR VALUE(vc_deploy_dir).
OS-CREATE-DIR "tests/util".

/* 2. Fixture valido */
OUTPUT TO VALUE(vc_valid_p).
PUT UNFORMATTED "/* Programa ABL sintacticamente valido */" SKIP.
PUT UNFORMATTED "DEFINE VARIABLE vi_num AS INTEGER NO-UNDO INITIAL 10." SKIP.
PUT UNFORMATTED "ASSIGN vi_num = vi_num * 2." SKIP.
OUTPUT CLOSE.

/* 3. Fixture con error de sintaxis */
OUTPUT TO VALUE(vc_invalid_p).
PUT UNFORMATTED "/* Programa con error sintactico intencional */" SKIP.
PUT UNFORMATTED "DEFINE VARIABLE vi_bad AS INTEGER NO-UNDO." SKIP.
PUT UNFORMATTED "ESTA_INSTRUCCION_NO_EXISTE_SINTAXIS_ERRONEA ;;;;" SKIP.
OUTPUT CLOSE.

/* 4. Fixture en carpeta util (debe ser excluido) */
OUTPUT TO VALUE(vc_util_p).
PUT UNFORMATTED "/* Programa utilitario en subdirectorio util */" SKIP.
PUT UNFORMATTED "DEFINE VARIABLE vc_msg AS CHARACTER NO-UNDO INITIAL 'util'." SKIP.
OUTPUT CLOSE.

/* 5. Fixture con extension no soportada .i */
OUTPUT TO VALUE(vc_include_i).
PUT UNFORMATTED "/* Archivo include */" SKIP.
PUT UNFORMATTED "&GLOBAL-DEFINE TEST_DEF 1" SKIP.
OUTPUT CLOSE.


/* =================================================================== */
/* PRUEBA 1: Compilacion Exitosa -> Staging -> Despliegue en Destino   */
/* =================================================================== */

RUN compileSingleFile (vc_valid_p, vc_staging_dir, vc_deploy_dir, OUTPUT vl_build_ok, OUTPUT vc_build_msg).

RUN assertTrue(vl_build_ok, "Programa valido debe compilar con exito").

/* Verificar que se genero en staging */
FILE-INFO:FILE-NAME = vc_staging_dir + "/test_prog_valid.r".
RUN assertTrue(FILE-INFO:FULL-PATHNAME <> ?, "El archivo .r debe existir en el directorio de STAGING").

/* Verificar que se desplego en destino */
FILE-INFO:FILE-NAME = vc_deploy_dir + "/test_prog_valid.r".
RUN assertTrue(FILE-INFO:FULL-PATHNAME <> ?, "El archivo .r debe haberse desplegado en el directorio FINAL").


/* =================================================================== */
/* PRUEBA 2: Compilacion Fallida -> Staging con Error -> NO DESPLEGADO */
/* =================================================================== */

RUN compileSingleFile (vc_invalid_p, vc_staging_dir, vc_deploy_dir, OUTPUT vl_build_ok, OUTPUT vc_build_msg).

RUN assertFalse(vl_build_ok, "Programa con error de sintaxis debe reportar fallo en compilacion").

/* REGLA DE ORO: En destino final NO debe existir el archivo desplegado */
FILE-INFO:FILE-NAME = vc_deploy_dir + "/test_prog_invalid.r".
RUN assertTrue(FILE-INFO:FULL-PATHNAME = ?, "El artefacto fallido NUNCA debe desplegarse en destino final").


/* =================================================================== */
/* PRUEBA 3: Exclusiones Automaticas (util y extensiones no permitidas)*/
/* =================================================================== */

/* Archivo en subdirectorio util */
RUN compileSingleFile (vc_util_p, vc_staging_dir, vc_deploy_dir, OUTPUT vl_build_ok, OUTPUT vc_build_msg).
RUN assertFalse(vl_build_ok, "Programa en subdirectorio 'util' debe ser omitido").
FILE-INFO:FILE-NAME = vc_deploy_dir + "/test_prog_util.r".
RUN assertTrue(FILE-INFO:FULL-PATHNAME = ?, "Programa en 'util' no debe ser desplegado").

/* Archivo include .i */
RUN compileSingleFile (vc_include_i, vc_staging_dir, vc_deploy_dir, OUTPUT vl_build_ok, OUTPUT vc_build_msg).
RUN assertFalse(vl_build_ok, "Archivo .i debe ser omitido").
FILE-INFO:FILE-NAME = vc_deploy_dir + "/test_include.r".
RUN assertTrue(FILE-INFO:FULL-PATHNAME = ?, "Archivo .i no debe ser desplegado").


/* =================================================================== */
/* LIMPIEZA DE ARTEFACTOS TEMPORALES                                   */
/* =================================================================== */

OS-DELETE VALUE(vc_valid_p).
OS-DELETE VALUE(vc_invalid_p).
OS-DELETE VALUE(vc_util_p).
OS-DELETE VALUE(vc_include_i).
OS-DELETE VALUE(vc_staging_dir + "/test_prog_valid.r").
OS-DELETE VALUE(vc_deploy_dir + "/test_prog_valid.r").

PUT UNFORMATTED "--- Fin test_build_engine.p ---" SKIP.
