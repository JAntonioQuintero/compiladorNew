/*------------------------------------------------------------------------
    File        : src/rules/RulesEngine.i
    Purpose     : Motor centralizado de reglas de compilación para OpenEdge 12.8.
                  Controla extensiones válidas (.p, .w, .cls), exclusión estricta
                  del directorio 'util' y detección de opciones especiales (V6FRAME).
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

/*------------------------------------------------------------------------
    Procedure   : isCompilable
    Purpose     : Determina si un archivo debe ser compilado según las reglas:
                  - Solo extensiones .p, .w, .cls
                  - Exclusión obligatoria de programas en subdirectorios 'util'
  ----------------------------------------------------------------------*/
PROCEDURE isCompilable:
    DEFINE INPUT  PARAMETER pcFilePath   AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plCompilable AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcReason     AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_norm_path AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_last_dot  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_ext       AS CHARACTER NO-UNDO.

    ASSIGN plCompilable = NO
           pcReason     = "".

    IF pcFilePath = ? OR TRIM(pcFilePath) = "" THEN DO:
        ASSIGN pcReason = "Ruta de archivo vacia o nula".
        RETURN.
    END.

    /* Normalizar separadores a barra diagonal standard */
    ASSIGN vc_norm_path = REPLACE(TRIM(pcFilePath), "\", "/").

    /* Regla de Exclusion 1: Subdirectorios 'util' */
    /* Excluye si la ruta inicia con util/ o contiene /util/ */
    IF vc_norm_path BEGINS "util/" OR INDEX(vc_norm_path, "/util/") > 0 THEN DO:
        ASSIGN plCompilable = NO
               pcReason     = "Excluido: El programa pertenece a un subdirectorio 'util'".
        RETURN.
    END.

    /* Regla de Extensiones: Unicamente .p, .w, .cls */
    ASSIGN vi_last_dot = R-INDEX(vc_norm_path, ".").
    IF vi_last_dot <= 0 THEN DO:
        ASSIGN plCompilable = NO
               pcReason     = "Excluido: Archivo sin extension".
        RETURN.
    END.

    ASSIGN vc_ext = LC(SUBSTRING(vc_norm_path, vi_last_dot)).

    IF vc_ext = ".p" OR vc_ext = ".w" OR vc_ext = ".cls" THEN DO:
        ASSIGN plCompilable = YES
               pcReason     = "OK: Extension soportada (" + vc_ext + ")".
    END.
    ELSE DO:
        ASSIGN plCompilable = NO
               pcReason     = "Excluido: Extension no permitida '" + vc_ext + "' (Solo .p, .w, .cls)".
    END.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : getCompileOptions
    Purpose     : Centraliza las directivas y opciones de la sentencia COMPILE.
                  Analiza el código fuente para determinar si requiere V6FRAME.
    Notes       : REQUIERE_VALIDACION_OE128: Validar que en OE 12.8 64-bit
                  la clausula V6FRAME no emita advertencias fatales.
  ----------------------------------------------------------------------*/
PROCEDURE getCompileOptions:
    DEFINE INPUT  PARAMETER pcFilePath       AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcCompileOptions AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcRuleNotes      AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_content AS LONGCHAR  NO-UNDO.
    DEFINE VARIABLE vc_search  AS CHARACTER NO-UNDO.

    ASSIGN pcCompileOptions = ""
           pcRuleNotes      = "".

    ASSIGN vc_search = SEARCH(pcFilePath).
    IF vc_search = ? THEN
        ASSIGN vc_search = pcFilePath. /* Intentar ruta relativa directa */

    IF SEARCH(vc_search) = ? THEN DO:
        ASSIGN pcRuleNotes = "ADVERTENCIA: Archivo no localizado en disco para analisis: " + pcFilePath.
        RETURN.
    END.

    /* Lectura de contenido mediante COPY-LOB para analisis de directivas */
    COPY-LOB FROM FILE vc_search TO vc_content NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ASSIGN pcRuleNotes = "ADVERTENCIA: Error leyendo archivo para reglas: " + ERROR-STATUS:GET-MESSAGE(1).
        RETURN.
    END.

    /* Regla V6FRAME:
       Reemplaza la llamada acoplada a util\ptestv6frame.p del codigo legado */
    IF vc_content MATCHES "*V6FRAME*" THEN DO:
        ASSIGN pcCompileOptions = (IF pcCompileOptions > "" THEN pcCompileOptions + " " ELSE "") + "V6FRAME"
               pcRuleNotes      = (IF pcRuleNotes > "" THEN pcRuleNotes + "; " ELSE "") + 
                                  "Regla V6FRAME aplicada [REQUIERE_VALIDACION_OE128]".
    END.

END PROCEDURE.
