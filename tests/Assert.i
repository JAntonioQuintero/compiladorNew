/*------------------------------------------------------------------------
    File        : tests/Assert.i
    Purpose     : Arnés de aserciones para desarrollo guiado por pruebas (TDD)
                  en Progress OpenEdge 12.8 / ABL.
    Author      : Refactorización Compilador OE 12.8
    Notes       : Compatible con ejecución interactiva y modo batch (-b).
  ----------------------------------------------------------------------*/

DEFINE VARIABLE gi_tests_run     AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE gi_tests_passed  AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE gi_tests_failed  AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE gi_asserts_count AS INTEGER NO-UNDO INITIAL 0.

PROCEDURE assertTrue:
    DEFINE INPUT PARAMETER pl_condition AS LOGICAL   NO-UNDO.
    DEFINE INPUT PARAMETER pc_message   AS CHARACTER NO-UNDO.

    ASSIGN gi_asserts_count = gi_asserts_count + 1.

    IF pl_condition = YES THEN DO:
        ASSIGN gi_tests_passed = gi_tests_passed + 1.
        PUT UNFORMATTED "  [PASS] " pc_message SKIP.
    END.
    ELSE DO:
        ASSIGN gi_tests_failed = gi_tests_failed + 1.
        PUT UNFORMATTED "  [FAIL] " pc_message SKIP.
    END.
END PROCEDURE.

PROCEDURE assertFalse:
    DEFINE INPUT PARAMETER pl_condition AS LOGICAL   NO-UNDO.
    DEFINE INPUT PARAMETER pc_message   AS CHARACTER NO-UNDO.

    RUN assertTrue(NOT (pl_condition = YES), pc_message).
END PROCEDURE.

PROCEDURE assertEqualsChar:
    DEFINE INPUT PARAMETER pc_expected AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pc_actual   AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pc_message  AS CHARACTER NO-UNDO.

    IF pc_expected = pc_actual THEN
        RUN assertTrue(YES, pc_message).
    ELSE
        RUN assertTrue(NO, pc_message + " (Esperado: '" + pc_expected + "', Obtenido: '" + pc_actual + "')").
END PROCEDURE.

PROCEDURE assertEqualsInt:
    DEFINE INPUT PARAMETER pi_expected AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pi_actual   AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER pc_message  AS CHARACTER NO-UNDO.

    IF pi_expected = pi_actual THEN
        RUN assertTrue(YES, pc_message).
    ELSE
        RUN assertTrue(NO, pc_message + " (Esperado: " + STRING(pi_expected) + ", Obtenido: " + STRING(pi_actual) + ")").
END PROCEDURE.

PROCEDURE assertEqualsLog:
    DEFINE INPUT PARAMETER pl_expected AS LOGICAL   NO-UNDO.
    DEFINE INPUT PARAMETER pl_actual   AS LOGICAL   NO-UNDO.
    DEFINE INPUT PARAMETER pc_message  AS CHARACTER NO-UNDO.

    IF pl_expected = pl_actual THEN
        RUN assertTrue(YES, pc_message).
    ELSE
        RUN assertTrue(NO, pc_message + " (Esperado: " + STRING(pl_expected) + ", Obtenido: " + STRING(pl_actual) + ")").
END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : getAssertTotals
    Purpose     : Expone los contadores locales de esta unidad de compilacion
                  (privados por definicion: cada test_*.p incluye su propia
                  copia de este .i) para que un invocador externo pueda
                  leerlos via RUN ... IN <handle> cuando la suite se ejecuto
                  con RUN ... PERSISTENT, y asi acumularlos en sus propios
                  contadores. Ver tests/TestRunner.p:runSuite.
  ----------------------------------------------------------------------*/
PROCEDURE getAssertTotals:
    DEFINE OUTPUT PARAMETER piAssertsCount AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER piTestsPassed  AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER piTestsFailed  AS INTEGER NO-UNDO.

    ASSIGN piAssertsCount = gi_asserts_count
           piTestsPassed  = gi_tests_passed
           piTestsFailed  = gi_tests_failed.
END PROCEDURE.

PROCEDURE printTestSummary:
    PUT UNFORMATTED "--------------------------------------------------" SKIP.
    PUT UNFORMATTED "Resumen de Pruebas: Aserciones=" STRING(gi_asserts_count)
                    " Pasadas=" STRING(gi_tests_passed)
                    " Falladas=" STRING(gi_tests_failed) SKIP.
    IF gi_tests_failed > 0 THEN
        PUT UNFORMATTED "ESTADO FINAL: ERROR (Pruebas fallidas detectadas)" SKIP.
    ELSE
        PUT UNFORMATTED "ESTADO FINAL: EXITO (Todas las pruebas pasaron)" SKIP.
    PUT UNFORMATTED "--------------------------------------------------" SKIP.
END PROCEDURE.
