/*------------------------------------------------------------------------
    File        : tests/test_propath_manager.p
    Purpose     : Suite de pruebas unitarias (TDD) para PropathManager.p
                  Valida determinismo, eliminación de duplicados, preservación
                  de precedencia y validación de rutas existentes.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{tests/Assert.i}
{src/core/PropathManager.i}

DEFINE VARIABLE vc_input_propath  AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc_result_propath AS CHARACTER NO-UNDO.
DEFINE VARIABLE vi_entry_count    AS INTEGER   NO-UNDO.
DEFINE VARIABLE vl_is_valid       AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vc_invalid_list   AS CHARACTER NO-UNDO.

PUT UNFORMATTED "--- Ejecutando test_propath_manager.p ---" SKIP.

/* =================================================================== */
/* PRUEBA 1: Deduplicacion de Entradas y Preservacion de Precedencia   */
/* =================================================================== */

ASSIGN vc_input_propath = "src,config,src,Documentacion,config,tests".
RUN buildDeterministicPropath (vc_input_propath, OUTPUT vc_result_propath).

RUN assertEqualsChar("src,config,Documentacion,tests", vc_result_propath, 
                     "Debe eliminar duplicados manteniendo el primer orden de aparicion").

/* Probar con espacios en blanco alrededor de las entradas */
ASSIGN vc_input_propath = "  src ,  config  , src  ,  tests ".
RUN buildDeterministicPropath (vc_input_propath, OUTPUT vc_result_propath).

RUN assertEqualsChar("src,config,tests", vc_result_propath, 
                     "Debe recortar espacios en blanco y eliminar duplicados").


/* =================================================================== */
/* PRUEBA 2: Normalizacion de Separadores                              */
/* =================================================================== */

ASSIGN vc_input_propath = "src\rules,src/rules,src\core".
RUN buildDeterministicPropath (vc_input_propath, OUTPUT vc_result_propath).

RUN assertEqualsChar("src/rules,src/core", vc_result_propath, 
                     "Debe unificar separadores y reconocer duplicados con diferente diagonal").


/* =================================================================== */
/* PRUEBA 3: Validacion de Existencia en Disco                         */
/* =================================================================== */

/* Rutas que si existen en el workspace */
ASSIGN vc_input_propath = "src,Documentacion,config,tests,ruta_inexistente_xyz123".
RUN validatePropathEntries (vc_input_propath, OUTPUT vl_is_valid, OUTPUT vc_invalid_list).

RUN assertFalse(vl_is_valid, "Debe detectar que existe al menos una ruta inexistente").
RUN assertTrue(LOOKUP("ruta_inexistente_xyz123", vc_invalid_list) > 0, 
               "La ruta inexistente debe reportarse en la lista de invalidas").

/* Rutas validas unicamente */
ASSIGN vc_input_propath = "src,Documentacion,config,tests".
RUN validatePropathEntries (vc_input_propath, OUTPUT vl_is_valid, OUTPUT vc_invalid_list).

RUN assertTrue(vl_is_valid, "Todas las rutas existentes deben validar en TRUE").
RUN assertEqualsChar("", vc_invalid_list, "No debe haber rutas invalidas reportadas").


/* =================================================================== */
/* PRUEBA 4: Generacion de PROPATH Efectivo Filtrado                   */
/* =================================================================== */

/* Debe descartar automaticamente rutas inexistentes si se solicita modo estricto */
ASSIGN vc_input_propath = "src,ruta_fantasma_456,Documentacion,src".
RUN getEffectivePropath (vc_input_propath, YES /* strictFilter */, OUTPUT vc_result_propath).

RUN assertEqualsChar("src,Documentacion", vc_result_propath, 
                     "PROPATH efectivo estricto debe omitir rutas inexistentes y duplicados").

PUT UNFORMATTED "--- Fin test_propath_manager.p ---" SKIP.
