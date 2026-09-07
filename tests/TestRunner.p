/*------------------------------------------------------------------------
    File        : tests/TestRunner.p
    Purpose     : Ejecutor principal de pruebas automatizadas (TDD)
                  para el compilador Progress OpenEdge 12.8.
    Author      : Refactorización Compilador OE 12.8
    Notes       : Ejecutable en modo batch: _progres -b -p tests/TestRunner.p
                  o prowin -b -p tests/TestRunner.p
  ----------------------------------------------------------------------*/

{tests/Assert.i}

DEFINE VARIABLE vc_test_to_run AS CHARACTER NO-UNDO.

ASSIGN vc_test_to_run = SESSION:PARAMETER.

PUT UNFORMATTED "==================================================" SKIP.
PUT UNFORMATTED "INICIANDO SUITE DE PRUEBAS AUTOMATIZADAS TDD" SKIP.
PUT UNFORMATTED "Entorno OpenEdge PROVERSION: " PROVERSION SKIP.
PUT UNFORMATTED "Fecha y Hora: " STRING(TODAY, "99/99/9999") " " STRING(TIME, "HH:MM:SS") SKIP.
PUT UNFORMATTED "==================================================" SKIP.

IF vc_test_to_run > "" THEN DO:
    PUT UNFORMATTED "Ejecutando prueba especifica: " vc_test_to_run SKIP.
    RUN runSuite (vc_test_to_run).
END.
ELSE DO:
    /* Ejecución por defecto de suites registradas */
    PUT UNFORMATTED "Ejecutando todas las suites registradas..." SKIP.

    RUN runSuite ("tests/test_rules_engine.p").
    RUN runSuite ("tests/test_propath_manager.p").
    RUN runSuite ("tests/test_config_manager.p").
    RUN runSuite ("tests/test_build_logger.p").
    RUN runSuite ("tests/test_build_engine.p").
    RUN runSuite ("tests/test_regression.p").
END.

PUT UNFORMATTED "==================================================" SKIP.
RUN printTestSummary.
PUT UNFORMATTED "==================================================" SKIP.

IF gi_tests_failed > 0 THEN
    SESSION:EXIT-CODE = 1.
ELSE
    SESSION:EXIT-CODE = 0.
QUIT.


/*------------------------------------------------------------------------
    Procedure   : runSuite
    Purpose     : Ejecuta una suite de pruebas (test_*.p) y acumula sus
                  resultados en los contadores de ESTE TestRunner.p.
    Notes       : Cada test_*.p incluye su PROPIA copia privada de
                  tests/Assert.i (una unidad de compilacion independiente),
                  por lo que sus contadores (gi_asserts_count, gi_tests_passed,
                  gi_tests_failed) NO son compartidos automaticamente con
                  quien la invoca. Ejecutarla con RUN ... PERSISTENT la
                  mantiene residente despues de correr su bloque principal
                  (donde ya se ejecutaron todas las aserciones), permitiendo
                  leer esos contadores via RUN getAssertTotals IN <handle>
                  antes de liberarla. Sin esto, el resumen final y el
                  SESSION:EXIT-CODE de este runner siempre reportarian
                  exito, sin importar cuantas aserciones fallaran realmente
                  en cada suite (bug detectado y corregido — ver
                  Documentacion/Informe_Ejecucion_Pruebas_2026-09-07.md).
  ----------------------------------------------------------------------*/
PROCEDURE runSuite:
    DEFINE INPUT PARAMETER pcSuitePath AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vh_suite      AS HANDLE    NO-UNDO.
    DEFINE VARIABLE vc_suite_r    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_suite_asrt AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_suite_pass AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_suite_fail AS INTEGER   NO-UNDO.

    ASSIGN vc_suite_r = SUBSTRING(pcSuitePath, 1, R-INDEX(pcSuitePath, ".") - 1) + ".r".

    IF SEARCH(vc_suite_r) = ? AND SEARCH(pcSuitePath) = ? THEN DO:
        PUT UNFORMATTED "ADVERTENCIA: Suite no localizada, se omite: " pcSuitePath SKIP.
        RETURN.
    END.

    RUN VALUE(pcSuitePath) PERSISTENT SET vh_suite NO-ERROR.

    IF ERROR-STATUS:ERROR OR NOT VALID-HANDLE(vh_suite) THEN DO:
        PUT UNFORMATTED "ERROR al ejecutar suite '" pcSuitePath "': " +
                        (IF ERROR-STATUS:ERROR THEN ERROR-STATUS:GET-MESSAGE(1) ELSE "fallo desconocido al iniciar la suite") SKIP.
        ASSIGN gi_tests_failed = gi_tests_failed + 1.
        IF VALID-HANDLE(vh_suite) THEN DELETE PROCEDURE vh_suite NO-ERROR.
        RETURN.
    END.

    RUN getAssertTotals IN vh_suite (OUTPUT vi_suite_asrt, OUTPUT vi_suite_pass, OUTPUT vi_suite_fail) NO-ERROR.

    ASSIGN gi_asserts_count = gi_asserts_count + vi_suite_asrt
           gi_tests_passed  = gi_tests_passed  + vi_suite_pass
           gi_tests_failed  = gi_tests_failed  + vi_suite_fail.

    DELETE PROCEDURE vh_suite NO-ERROR.

END PROCEDURE.
