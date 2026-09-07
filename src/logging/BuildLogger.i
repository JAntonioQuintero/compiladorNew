/*------------------------------------------------------------------------
    File        : src/logging/BuildLogger.i
    Purpose     : Registrador estructurado de compilación para OpenEdge 12.8.
                  Registra versión de OpenEdge, PROPATH efectivo, origen,
                  staging, destino, resultado, errores y estado de despliegue.
                  Soporta emisión en tiempo real hacia compila02.w / consola.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

DEFINE TEMP-TABLE tt_build_entry NO-UNDO
    FIELD cSourceFile   AS CHARACTER
    FIELD cStagingPath  AS CHARACTER
    FIELD cDeployPath   AS CHARACTER
    FIELD lSuccess      AS LOGICAL
    FIELD cErrorMsg     AS CHARACTER
    FIELD iErrorNum     AS INTEGER
    FIELD iErrorLine    AS INTEGER
    FIELD cDeployStatus AS CHARACTER
    FIELD cTimestamp    AS CHARACTER.

DEFINE VARIABLE gc_build_id         AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE gc_build_propath    AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE gc_build_deploy_dir AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE gc_build_start_time AS CHARACTER NO-UNDO INITIAL "".
DEFINE VARIABLE gh_log_listener     AS HANDLE    NO-UNDO INITIAL ?.

/*------------------------------------------------------------------------
    Procedure   : initBuildLogger
    Purpose     : Inicializa una nueva sesión de compilación y limpia registros.
  ----------------------------------------------------------------------*/
PROCEDURE initBuildLogger:
    DEFINE INPUT PARAMETER pcBuildId   AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcPropath   AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcDeployDir AS CHARACTER NO-UNDO.

    EMPTY TEMP-TABLE tt_build_entry.

    ASSIGN gc_build_id         = (IF pcBuildId > "" THEN pcBuildId 
                                  ELSE "BUILD_" + STRING(YEAR(TODAY), "9999") + 
                                       STRING(MONTH(TODAY), "99") + 
                                       STRING(DAY(TODAY), "99") + "_" + 
                                       STRING(TIME, "99999"))
           gc_build_propath    = pcPropath
           gc_build_deploy_dir = pcDeployDir
           gc_build_start_time = STRING(TODAY, "99/99/9999") + " " + STRING(TIME, "HH:MM:SS").

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : setLogListener
    Purpose     : Asocia un procedimiento gráfico flotante (ej. compila02.w)
                  para recibir mensajes de progreso en tiempo real.
  ----------------------------------------------------------------------*/
PROCEDURE setLogListener:
    DEFINE INPUT PARAMETER phListener AS HANDLE NO-UNDO.
    ASSIGN gh_log_listener = phListener.
END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : logMessage
    Purpose     : Emite un mensaje de texto hacia la consola y el listener.
  ----------------------------------------------------------------------*/
PROCEDURE logMessage:
    DEFINE INPUT PARAMETER pcMsg AS CHARACTER NO-UNDO.

    /* Notificar a compila02.w si está activo */
    IF VALID-HANDLE(gh_log_listener) THEN DO:
        RUN CargaMensaje IN gh_log_listener (pcMsg + "~n") NO-ERROR.
    END.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : logFileResult
    Purpose     : Registra el resultado individual de la compilación de un archivo.
  ----------------------------------------------------------------------*/
PROCEDURE logFileResult:
    DEFINE INPUT PARAMETER pcSourceFile  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcStagingPath AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER pcDeployPath  AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER plSuccess     AS LOGICAL   NO-UNDO.
    DEFINE INPUT PARAMETER pcErrorMsg    AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER piErrNum      AS INTEGER   NO-UNDO.
    DEFINE INPUT PARAMETER piErrLine     AS INTEGER   NO-UNDO.

    CREATE tt_build_entry.
    ASSIGN tt_build_entry.cSourceFile   = pcSourceFile
           tt_build_entry.cStagingPath  = pcStagingPath
           tt_build_entry.cDeployPath   = pcDeployPath
           tt_build_entry.lSuccess      = plSuccess
           tt_build_entry.cErrorMsg     = pcErrorMsg
           tt_build_entry.iErrorNum     = piErrNum
           tt_build_entry.iErrorLine    = piErrLine
           tt_build_entry.cDeployStatus = (IF plSuccess THEN "DEPLOYED" ELSE "BLOCKED_DUE_TO_ERRORS")
           tt_build_entry.cTimestamp    = STRING(TIME, "HH:MM:SS").

    IF plSuccess THEN
        RUN logMessage ("[OK] " + pcSourceFile + " -> " + pcDeployPath).
    ELSE
        RUN logMessage ("[FALLO] " + pcSourceFile + " (" + STRING(piErrNum) + "): " + pcErrorMsg).

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : getBuildTotals
    Purpose     : Retorna el conteo consolidado de archivos exitosos y fallidos.
  ----------------------------------------------------------------------*/
PROCEDURE getBuildTotals:
    DEFINE OUTPUT PARAMETER piSuccess AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER piFailed  AS INTEGER NO-UNDO.

    ASSIGN piSuccess = 0
           piFailed  = 0.

    FOR EACH tt_build_entry NO-LOCK:
        IF tt_build_entry.lSuccess THEN
            ASSIGN piSuccess = piSuccess + 1.
        ELSE
            ASSIGN piFailed = piFailed + 1.
    END.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : getLoggerBuildId
    Purpose     : Retorna el identificador del build actual.
  ----------------------------------------------------------------------*/
PROCEDURE getLoggerBuildId:
    DEFINE OUTPUT PARAMETER pcBuildId AS CHARACTER NO-UNDO.
    ASSIGN pcBuildId = gc_build_id.
END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : writeBuildReport
    Purpose     : Persiste el reporte estructurado completo en formato texto/log.
  ----------------------------------------------------------------------*/
PROCEDURE writeBuildReport:
    DEFINE INPUT PARAMETER pcReportPath AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vi_ok   AS INTEGER NO-UNDO.
    DEFINE VARIABLE vi_fail AS INTEGER NO-UNDO.

    RUN getBuildTotals (OUTPUT vi_ok, OUTPUT vi_fail).

    OUTPUT TO VALUE(pcReportPath) NO-ECHO.

    PUT UNFORMATTED "================================================================================" SKIP.
    PUT UNFORMATTED "REPORTE ESTRUCTURADO DE COMPILACION - OPENEDGE 12.8" SKIP.
    PUT UNFORMATTED "================================================================================" SKIP.
    PUT UNFORMATTED "BUILD ID               : " gc_build_id SKIP.
    PUT UNFORMATTED "FECHA DE INICIO        : " gc_build_start_time SKIP.
    PUT UNFORMATTED "OPENEDGE PROVERSION    : " PROVERSION SKIP.
    PUT UNFORMATTED "PROPATH EFECTIVO       : " gc_build_propath SKIP.
    PUT UNFORMATTED "DIRECTORIO DESPLIEGUE  : " gc_build_deploy_dir SKIP.
    PUT UNFORMATTED "TOTAL EXITOSOS         : " STRING(vi_ok) SKIP.
    PUT UNFORMATTED "TOTAL FALLIDOS         : " STRING(vi_fail) SKIP.
    PUT UNFORMATTED "--------------------------------------------------------------------------------" SKIP.
    PUT UNFORMATTED "DETALLE DE PROGRAMAS COMPILADOS:" SKIP.
    PUT UNFORMATTED "--------------------------------------------------------------------------------" SKIP.

    FOR EACH tt_build_entry NO-LOCK BY tt_build_entry.cSourceFile:
        IF tt_build_entry.lSuccess THEN DO:
            PUT UNFORMATTED "[EXITO] " tt_build_entry.cSourceFile 
                            " -> Staging: " tt_build_entry.cStagingPath
                            " -> Despliegue: " tt_build_entry.cDeployPath SKIP.
        END.
        ELSE DO:
            PUT UNFORMATTED "[FALLO] " tt_build_entry.cSourceFile 
                            " [NO DESPLEGADO - ARTEFACTO RETENIDO]" SKIP.
            PUT UNFORMATTED "        Error #" STRING(tt_build_entry.iErrorNum) 
                            " en linea/offset " STRING(tt_build_entry.iErrorLine)
                            ": " tt_build_entry.cErrorMsg SKIP.
        END.
    END.

    PUT UNFORMATTED "================================================================================" SKIP.
    PUT UNFORMATTED "FIN DEL REPORTE" SKIP.

    OUTPUT CLOSE.

END PROCEDURE.
