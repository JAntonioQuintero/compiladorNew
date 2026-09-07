/*------------------------------------------------------------------------
    File        : src/core/BuildEngine.i
    Purpose     : Motor desacoplado de compilación para OpenEdge 12.8.
                  Implementa el ciclo de vida de Build y Deploy separado:
                  1. Filtra extensiones (.p, .w, .cls) y excluye 'util'
                  2. Evalúa reglas especiales (V6FRAME)
                  3. Compila primero hacia un directorio de staging aislado
                  4. Bloquea el despliegue si la compilación falla
                  5. Despliega artefactos .r únicamente si la compilación fue exitosa
                  6. Registra métricas estructuradas en BuildLogger
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

/*------------------------------------------------------------------------
    Procedure   : compileSingleFile
    Purpose     : Compila un archivo individual en staging y, si no hubo errores,
                  lo despliega en el directorio final.
  ----------------------------------------------------------------------*/
PROCEDURE compileSingleFile:
    DEFINE INPUT  PARAMETER pcSourceFile  AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcStagingDir  AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcDeployDir   AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plSuccess     AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMessage     AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vl_compilable   AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE vc_reason       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_options      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_notes        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_base_name    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_dot          AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_r_name       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_staged_r     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_deploy_r     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_norm_source  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_abs_source   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_error_msg    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_err_num      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_err_line     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_msg_idx      AS INTEGER   NO-UNDO.

    ASSIGN plSuccess    = NO
           pcMessage    = ""
           vc_error_msg = ""
           vi_err_num   = 0
           vi_err_line  = 0.

    /* 1. Validación de reglas de inclusión/exclusión */
    RUN isCompilable (pcSourceFile, OUTPUT vl_compilable, OUTPUT vc_reason).
    IF NOT vl_compilable THEN DO:
        ASSIGN plSuccess = NO
               pcMessage = "Omitido: " + vc_reason.
        RETURN.
    END.

    /* 2. Determinación del nombre de artefacto .r */
    ASSIGN vc_norm_source = REPLACE(TRIM(pcSourceFile), "\", "/").
    ASSIGN vc_base_name   = ENTRY(NUM-ENTRIES(vc_norm_source, "/"), vc_norm_source, "/").
    ASSIGN vi_dot         = R-INDEX(vc_base_name, ".").
    IF vi_dot > 0 THEN
        ASSIGN vc_r_name = SUBSTRING(vc_base_name, 1, vi_dot - 1) + ".r".
    ELSE
        ASSIGN vc_r_name = vc_base_name + ".r".

    ASSIGN vc_staged_r = REPLACE(TRIM(pcStagingDir), "\", "/") + "/" + vc_r_name
           vc_deploy_r = REPLACE(TRIM(pcDeployDir), "\", "/") + "/" + vc_r_name.

    /* Asegurar que los directorios existan */
    OS-CREATE-DIR VALUE(pcStagingDir).
    OS-CREATE-DIR VALUE(pcDeployDir).

    /* 2b. Resolver el fuente a ruta ABSOLUTA antes de compilar.
       Motivo: COMPILE ... SAVE INTO replica dentro del staging cualquier
       subdirectorio presente en una ruta FUENTE relativa (ej. "tests/x.p"
       termina generando "<staging>/tests/x.r", no "<staging>/x.r"), lo que
       rompe la ubicacion plana asumida por vc_staged_r. Compilando siempre
       con la ruta absoluta, SAVE INTO guarda el .r de forma plana en la
       raiz del directorio de staging, tal como espera este motor. */
    FILE-INFO:FILE-NAME = pcSourceFile.
    ASSIGN vc_abs_source = FILE-INFO:FULL-PATHNAME.
    IF vc_abs_source = ? THEN DO:
        ASSIGN plSuccess = NO
               pcMessage = "Fallo: Archivo fuente no localizado en disco: " + pcSourceFile.
        RETURN.
    END.

    /* 3. Consulta de reglas especiales (ej. V6FRAME para OE 12.8) */
    RUN getCompileOptions (pcSourceFile, OUTPUT vc_options, OUTPUT vc_notes).

    /* 4. Ejecución de compilación hacia STAGING */
    /* REQUIERE_VALIDACION_OE128: Clausula V6FRAME en OpenEdge 12.8 */
    IF LOOKUP("V6FRAME", vc_options, " ") > 0 THEN DO:
        COMPILE VALUE(vc_abs_source) SAVE INTO VALUE(pcStagingDir) V6FRAME NO-ERROR.
    END.
    ELSE DO:
        COMPILE VALUE(vc_abs_source) SAVE INTO VALUE(pcStagingDir) NO-ERROR.
    END.

    /* 5. Detección exhaustiva de errores de compilación */
    IF COMPILER:ERROR OR ERROR-STATUS:ERROR THEN DO:
        ASSIGN plSuccess = NO.
        
        DO vi_msg_idx = 1 TO ERROR-STATUS:NUM-MESSAGES:
            ASSIGN vc_error_msg = vc_error_msg + (IF vc_error_msg > "" THEN " | " ELSE "") + ERROR-STATUS:GET-MESSAGE(vi_msg_idx)
                   vi_err_num   = ERROR-STATUS:GET-NUMBER(vi_msg_idx).
        END.

        IF vc_error_msg = "" AND COMPILER:NUM-MESSAGES > 0 THEN DO:
            DO vi_msg_idx = 1 TO COMPILER:NUM-MESSAGES:
                ASSIGN vc_error_msg = vc_error_msg + (IF vc_error_msg > "" THEN " | " ELSE "") + COMPILER:GET-MESSAGE(vi_msg_idx)
                       vi_err_num   = COMPILER:GET-NUMBER(vi_msg_idx).
            END.
        END.

        IF vc_error_msg = "" THEN
            ASSIGN vc_error_msg = "Error de sintaxis o resolucion en tiempo de compilacion".
    END.
    ELSE DO:
        ASSIGN plSuccess = YES.
    END.

    /* 6. Despliegue Condicional Atómico */
    IF plSuccess THEN DO:
        /* Verificar existencia del artefacto en staging */
        FILE-INFO:FILE-NAME = vc_staged_r.
        IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
            OS-COPY VALUE(vc_staged_r) VALUE(vc_deploy_r).
            FILE-INFO:FILE-NAME = vc_deploy_r.
            IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
                ASSIGN pcMessage = "OK: Compilado en staging y desplegado en " + vc_deploy_r.
            END.
            ELSE DO:
                ASSIGN plSuccess = NO
                       pcMessage = "Fallo de despliegue al copiar artefacto a destino final".
            END.
        END.
        ELSE DO:
            ASSIGN plSuccess = NO
                   pcMessage = "Fallo: Artefacto no generado en staging a pesar de no reportar error fatal".
        END.
    END.
    ELSE DO:
        /* RESTRICTIVO: Si hubo fallo, el archivo NUNCA se despliega a destino final */
        ASSIGN pcMessage = "Compilacion fallida. Despliegue bloqueado: " + vc_error_msg.
    END.

    /* 7. Registro estructurado */
    RUN logFileResult (pcSourceFile, vc_staged_r, vc_deploy_r, plSuccess, vc_error_msg, vi_err_num, vi_err_line) NO-ERROR.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : runFullBuild
    Purpose     : Orquestador desacoplado no-GUI de un build completo.
  ----------------------------------------------------------------------*/
PROCEDURE runFullBuild:
    DEFINE INPUT  PARAMETER pcSourceFileList AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcStagingDir     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcDeployDir      AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcPropathList    AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcReportLogPath  AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER piTotalCompiled  AS INTEGER   NO-UNDO.
    DEFINE OUTPUT PARAMETER piTotalFailed    AS INTEGER   NO-UNDO.

    DEFINE VARIABLE vc_effective_pp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_idx          AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_total_files  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_file         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vl_file_ok      AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE vc_msg          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_build_id     AS CHARACTER NO-UNDO.

    ASSIGN piTotalCompiled = 0
           piTotalFailed   = 0.

    /* Construir identificador único del build */
    ASSIGN vc_build_id = "BUILD_" + STRING(YEAR(TODAY), "9999") + 
                         STRING(MONTH(TODAY), "99") + 
                         STRING(DAY(TODAY), "99") + "_" + 
                         STRING(TIME, "99999").

    /* Configuración determinística de PROPATH */
    RUN getEffectivePropath (pcPropathList, YES, OUTPUT vc_effective_pp).
    IF vc_effective_pp > "" THEN
        ASSIGN PROPATH = vc_effective_pp.

    /* Inicializar registrador estructurado */
    RUN initBuildLogger (vc_build_id, PROPATH, pcDeployDir).

    RUN logMessage ("Iniciando build desatendido (" + vc_build_id + ")...").

    ASSIGN vi_total_files = NUM-ENTRIES(pcSourceFileList).
    DO vi_idx = 1 TO vi_total_files:
        ASSIGN vc_file = TRIM(ENTRY(vi_idx, pcSourceFileList)).
        IF vc_file = "" THEN NEXT.

        RUN compileSingleFile (vc_file, pcStagingDir, pcDeployDir, OUTPUT vl_file_ok, OUTPUT vc_msg).
        IF vl_file_ok THEN
            ASSIGN piTotalCompiled = piTotalCompiled + 1.
        ELSE
            ASSIGN piTotalFailed = piTotalFailed + 1.
    END.

    /* Persistir reporte final si se proporcionó ruta */
    IF pcReportLogPath > "" THEN
        RUN writeBuildReport (pcReportLogPath).

    RUN logMessage ("Build finalizado: Exitosos=" + STRING(piTotalCompiled) + " Fallidos=" + STRING(piTotalFailed)).

END PROCEDURE.
