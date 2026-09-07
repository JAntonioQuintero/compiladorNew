/*------------------------------------------------------------------------
    File        : src/core/PropathManager.i
    Purpose     : Gestión determinística del PROPATH para OpenEdge 12.8.
                  Deduplicación, normalización de separadores, validación
                  de existencia en disco y cálculo de PROPATH efectivo.
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

/*------------------------------------------------------------------------
    Procedure   : buildDeterministicPropath
    Purpose     : Normaliza y elimina duplicados preservando precedencia.
  ----------------------------------------------------------------------*/
PROCEDURE buildDeterministicPropath:
    DEFINE INPUT  PARAMETER pcPropathList   AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcResultPropath AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vi_idx        AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_total      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_entry      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vc_norm_entry AS CHARACTER NO-UNDO.

    ASSIGN pcResultPropath = "".

    IF pcPropathList = ? OR TRIM(pcPropathList) = "" THEN
        RETURN.

    ASSIGN vi_total = NUM-ENTRIES(pcPropathList).

    DO vi_idx = 1 TO vi_total:
        ASSIGN vc_entry = TRIM(ENTRY(vi_idx, pcPropathList)).
        
        IF vc_entry = "" THEN NEXT.

        /* Normalizar separadores a barra diagonal */
        ASSIGN vc_norm_entry = REPLACE(vc_entry, "\", "/").

        /* Quitar barra diagonal final si no es ruta raiz */
        IF LENGTH(vc_norm_entry) > 1 AND SUBSTRING(vc_norm_entry, LENGTH(vc_norm_entry), 1) = "/" THEN
            ASSIGN vc_norm_entry = SUBSTRING(vc_norm_entry, 1, LENGTH(vc_norm_entry) - 1).

        /* Deduplicar preservando la primera aparicion */
        IF LOOKUP(vc_norm_entry, pcResultPropath) = 0 THEN DO:
            IF pcResultPropath = "" THEN
                ASSIGN pcResultPropath = vc_norm_entry.
            ELSE
                ASSIGN pcResultPropath = pcResultPropath + "," + vc_norm_entry.
        END.
    END.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : validatePropathEntries
    Purpose     : Verifica que cada ruta especificada exista fisicamente en disco.
  ----------------------------------------------------------------------*/
PROCEDURE validatePropathEntries:
    DEFINE INPUT  PARAMETER pcPropathList  AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER plIsValid      AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcInvalidList  AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vi_idx   AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_total AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_entry AS CHARACTER NO-UNDO.

    ASSIGN plIsValid     = YES
           pcInvalidList = "".

    IF pcPropathList = ? OR TRIM(pcPropathList) = "" THEN
        RETURN.

    ASSIGN vi_total = NUM-ENTRIES(pcPropathList).

    DO vi_idx = 1 TO vi_total:
        ASSIGN vc_entry = TRIM(ENTRY(vi_idx, pcPropathList)).
        IF vc_entry = "" THEN NEXT.

        /* Verificacion de existencia fisica en disco */
        FILE-INFO:FILE-NAME = vc_entry.
        IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
            ASSIGN plIsValid = NO.
            IF pcInvalidList = "" THEN
                ASSIGN pcInvalidList = vc_entry.
            ELSE
                ASSIGN pcInvalidList = pcInvalidList + "," + vc_entry.
        END.
    END.

END PROCEDURE.


/*------------------------------------------------------------------------
    Procedure   : getEffectivePropath
    Purpose     : Retorna el PROPATH deterministico deduplicado, con opcion
                  de filtrar unicamente rutas fisicamente validas.
  ----------------------------------------------------------------------*/
PROCEDURE getEffectivePropath:
    DEFINE INPUT  PARAMETER pcPropathList     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER plStrictFilter    AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcEffectivePropath AS CHARACTER NO-UNDO.

    DEFINE VARIABLE vc_dedup AS CHARACTER NO-UNDO.
    DEFINE VARIABLE vi_idx   AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vi_total AS INTEGER   NO-UNDO.
    DEFINE VARIABLE vc_entry AS CHARACTER NO-UNDO.

    ASSIGN pcEffectivePropath = "".

    RUN buildDeterministicPropath (pcPropathList, OUTPUT vc_dedup).

    IF NOT plStrictFilter THEN DO:
        ASSIGN pcEffectivePropath = vc_dedup.
        RETURN.
    END.

    ASSIGN vi_total = NUM-ENTRIES(vc_dedup).
    DO vi_idx = 1 TO vi_total:
        ASSIGN vc_entry = ENTRY(vi_idx, vc_dedup).
        
        FILE-INFO:FILE-NAME = vc_entry.
        IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
            IF pcEffectivePropath = "" THEN
                ASSIGN pcEffectivePropath = vc_entry.
            ELSE
                ASSIGN pcEffectivePropath = pcEffectivePropath + "," + vc_entry.
        END.
    END.

END PROCEDURE.
