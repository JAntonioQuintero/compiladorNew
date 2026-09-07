/*------------------------------------------------------------------------
    File        : src/config/ConfigManager.i
    Purpose     : Gestor de configuración y catálogo de sistemas para OpenEdge 12.8.
                  Reemplaza el acoplamiento de BuscaSistema y Sinc-Estructura,
                  elimina restricciones a versiones 9/11, soporta OE 12.8
                  y provee respaldo preventivo con timestamp para compilador.csv.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

DEFINE TEMP-TABLE tt_sistema NO-UNDO
    FIELD cSistema              AS CHARACTER
    FIELD cDirectorioFuente     AS CHARACTER
    FIELD cDirectorioCompilados AS CHARACTER
    FIELD cPropathExtra         AS CHARACTER
    FIELD cActivo               AS CHARACTER
    INDEX idx_sis IS PRIMARY UNIQUE cSistema.

DEFINE VARIABLE gc_target_version AS CHARACTER NO-UNDO INITIAL "12.8".
DEFINE VARIABLE gc_work_dir       AS CHARACTER NO-UNDO INITIAL ".".
DEFINE VARIABLE gc_staging_dir    AS CHARACTER NO-UNDO INITIAL "build/staging".
DEFINE VARIABLE gc_deploy_dir     AS CHARACTER NO-UNDO INITIAL "compilados".
DEFINE VARIABLE gc_log_dir        AS CHARACTER NO-UNDO INITIAL "build/logs".
DEFINE VARIABLE gc_catalog_path   AS CHARACTER NO-UNDO INITIAL "config/compilador.default.csv".

/*------------------------------------------------------------------------
    Procedure   : getTargetOpenEdgeVersion
    Purpose     : Retorna la versión objetivo configurada (OpenEdge 12.8)
  ----------------------------------------------------------------------*/
PROCEDURE getTargetOpenEdgeVersion:
    DEFINE OUTPUT PARAMETER pcVersion AS CHARACTER NO-UNDO.
    ASSIGN pcVersion = gc_target_version.
END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : isVersionSupported
    Purpose     : Valida si la versión de Progress/OpenEdge es admitida.
                  Permite cualquier versión (no limitado a 9, 11 o 12).
  ----------------------------------------------------------------------*/
PROCEDURE isVersionSupported:
    DEFINE INPUT  PARAMETER pcVersion   AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plSupported AS LOGICAL   NO-UNDO.

    ASSIGN plSupported = NO.

    IF pcVersion = ? OR TRIM(pcVersion) = "" THEN
        RETURN.

    /* Soporta 12.8 y no se limita rígidamente a versiones fijas */
    ASSIGN plSupported = YES.
END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : loadCatalog
    Purpose     : Carga y parsea el archivo de catálogo (compilador.csv)
  ----------------------------------------------------------------------*/
PROCEDURE loadCatalog:
    DEFINE INPUT  PARAMETER pcCatalogFile AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plSuccess     AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMessage     AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_line      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_path      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vl_is_header AS LOGICAL   NO-UNDO INITIAL YES.
    DEFINE VARIABLE vi_rec_count AS INTEGER   NO-UNDO INITIAL 0.

    ASSIGN plSuccess = NO
           pcMessage = "".

    ASSIGN vc_path = (IF pcCatalogFile > "" THEN pcCatalogFile ELSE gc_catalog_path).

    FILE-INFO:FILE-NAME = vc_path.
    IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
        /* Si no existe la ruta dada, intentar compilador.csv en raiz */
        IF SEARCH("compilador.csv") <> ? THEN
            ASSIGN vc_path = "compilador.csv".
        ELSE IF SEARCH(gc_catalog_path) <> ? THEN
            ASSIGN vc_path = gc_catalog_path.
        ELSE DO:
            ASSIGN pcMessage = "Archivo de catalogo no localizado: " + vc_path.
            RETURN.
        END.
    END.

    EMPTY TEMP-TABLE tt_sistema.

    INPUT FROM VALUE(vc_path) NO-ECHO.
    IF ERROR-STATUS:ERROR THEN DO:
        ASSIGN pcMessage = "Error al abrir catalogo: " + ERROR-STATUS:GET-MESSAGE(1).
        RETURN.
    END.

    REPEAT:
        IMPORT UNFORMATTED vc_line.
        IF vc_line = ? OR TRIM(vc_line) = "" THEN NEXT.

        /* Omitir encabezado si contiene nombres de columnas */
        IF vl_is_header AND (ENTRY(1, vc_line) = "Sistema" OR INDEX(vc_line, "Directorio") > 0) THEN DO:
            ASSIGN vl_is_header = NO.
            NEXT.
        END.
        ASSIGN vl_is_header = NO.

        CREATE tt_sistema.
        ASSIGN tt_sistema.cSistema              = TRIM(ENTRY(1, vc_line))
               tt_sistema.cDirectorioFuente     = (IF NUM-ENTRIES(vc_line) >= 2 THEN TRIM(ENTRY(2, vc_line)) ELSE "")
               tt_sistema.cDirectorioCompilados = (IF NUM-ENTRIES(vc_line) >= 3 THEN TRIM(ENTRY(3, vc_line)) ELSE "")
               tt_sistema.cPropathExtra         = (IF NUM-ENTRIES(vc_line) >= 4 THEN TRIM(ENTRY(4, vc_line)) ELSE "")
               tt_sistema.cActivo               = (IF NUM-ENTRIES(vc_line) >= 5 THEN TRIM(ENTRY(5, vc_line)) ELSE "SI").
    END.
    INPUT CLOSE.

    /* Conteo directo por iteracion: HAS-RECORDS no es un atributo valido
       sobre el buffer por defecto de una temp-table estatica (error 4052);
       se evita esa ambiguedad contando registros de forma explicita. */
    FOR EACH tt_sistema NO-LOCK:
        ASSIGN vi_rec_count = vi_rec_count + 1.
    END.

    ASSIGN plSuccess = YES
           pcMessage = "Catalogo cargado exitosamente (" + STRING(vi_rec_count) + ")".

END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : findSystemConfig
    Purpose     : Sustituto modular y desacoplado de BuscaSistema.
                  Retorna la configuración del sistema consultado.
  ----------------------------------------------------------------------*/
PROCEDURE findSystemConfig:
    DEFINE INPUT  PARAMETER pcSistema        AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plFound          AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcFuente         AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcDestino        AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcExtraPropath   AS CHARACTER NO-UNDO.

    ASSIGN plFound        = NO
           pcFuente       = ""
           pcDestino      = ""
           pcExtraPropath = "".

    FIND FIRST tt_sistema WHERE tt_sistema.cSistema = TRIM(pcSistema) NO-LOCK NO-ERROR.
    IF AVAILABLE tt_sistema THEN DO:
        ASSIGN plFound        = YES
               pcFuente       = tt_sistema.cDirectorioFuente
               pcDestino      = tt_sistema.cDirectorioCompilados
               pcExtraPropath = tt_sistema.cPropathExtra.
    END.

END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : backupCatalog
    Purpose     : Genera copia de seguridad (.bak.timestamp) de compilador.csv
                  antes de realizar cualquier escritura o sincronización.
  ----------------------------------------------------------------------*/
PROCEDURE backupCatalog:
    DEFINE INPUT  PARAMETER pcCatalogFile AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcBackupFile  AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plSuccess     AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMessage     AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_timestamp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_time_num  AS INTEGER   NO-UNDO.

    ASSIGN plSuccess    = NO
           pcMessage    = ""
           pcBackupFile = "".

    FILE-INFO:FILE-NAME = pcCatalogFile.
    IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
        ASSIGN pcMessage = "No se puede respaldar: archivo inexistente (" + pcCatalogFile + ")".
        RETURN.
    END.

    ASSIGN vi_time_num  = TIME
           vc_timestamp = STRING(YEAR(TODAY), "9999") + 
                          STRING(MONTH(TODAY), "99") + 
                          STRING(DAY(TODAY), "99") + "_" + 
                          STRING(vi_time_num, "99999").

    ASSIGN pcBackupFile = pcCatalogFile + ".bak." + vc_timestamp.

    OS-COPY VALUE(pcCatalogFile) VALUE(pcBackupFile).

    FILE-INFO:FILE-NAME = pcBackupFile.
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
        ASSIGN plSuccess = YES
               pcMessage = "Respaldo generado en: " + pcBackupFile.
    END.
    ELSE DO:
        ASSIGN pcMessage = "Error al intentar crear copia de respaldo en disco: " + pcBackupFile.
    END.

END PROCEDURE.

/*------------------------------------------------------------------------
    Procedure   : saveOrUpdateSystem
    Purpose     : Guarda o actualiza un registro de sistema en compilador.csv,
                  garantizando respaldo previo y consistencia estructural.
  ----------------------------------------------------------------------*/
PROCEDURE saveOrUpdateSystem:
    DEFINE INPUT  PARAMETER pcCatalogFile AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcSistema     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcFuente      AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcDestino     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcExtraPP     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcActivo      AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plSuccess     AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMessage     AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_bak_file AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vl_bak_ok   AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE vc_bak_msg  AS CHARACTER NO-UNDO.

    ASSIGN plSuccess = NO
           pcMessage = "".

    IF pcSistema = ? OR TRIM(pcSistema) = "" THEN DO:
        ASSIGN pcMessage = "El identificador de sistema no puede ser nulo o vacio".
        RETURN.
    END.

    /* Respaldo preventivo obligatorio antes de modificar */
    RUN backupCatalog (pcCatalogFile, OUTPUT vc_bak_file, OUTPUT vl_bak_ok, OUTPUT vc_bak_msg).

    /* Upsert en la tabla temporal */
    FIND FIRST tt_sistema WHERE tt_sistema.cSistema = TRIM(pcSistema) NO-ERROR.
    IF NOT AVAILABLE tt_sistema THEN DO:
        CREATE tt_sistema.
        ASSIGN tt_sistema.cSistema = TRIM(pcSistema).
    END.

    ASSIGN tt_sistema.cDirectorioFuente     = TRIM(pcFuente)
           tt_sistema.cDirectorioCompilados = TRIM(pcDestino)
           tt_sistema.cPropathExtra         = TRIM(pcExtraPP)
           tt_sistema.cActivo               = (IF pcActivo > "" THEN TRIM(pcActivo) ELSE "SI").

    /* Reescribir archivo con formato CSV limpio y encabezados */
    OUTPUT TO VALUE(pcCatalogFile) NO-ECHO.
    PUT UNFORMATTED "Sistema,DirectorioFuente,DirectorioCompilados,PropathExtra,Activo" SKIP.
    
    FOR EACH tt_sistema BY tt_sistema.cSistema:
        PUT UNFORMATTED tt_sistema.cSistema ","
                        tt_sistema.cDirectorioFuente ","
                        tt_sistema.cDirectorioCompilados ","
                        tt_sistema.cPropathExtra ","
                        tt_sistema.cActivo SKIP.
    END.
    OUTPUT CLOSE.

    ASSIGN plSuccess = YES
           pcMessage = "Sistema '" + pcSistema + "' actualizado con exito en catalogo.".

END PROCEDURE.
