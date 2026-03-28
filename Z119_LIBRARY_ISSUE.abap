*&---------------------------------------------------------------------*
*& Report Z119_LIBRARY_ISSUE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z119_LIBRARY_ISSUE.

TABLES : ztabu_lib.
TYPE-POOLS: slis.

"SELECTION SCREEN------
SELECT-OPTIONS:
  s_bookid FOR ztabu_lib-book_id,
  s_bname FOR ztabu_lib-book_name,
  s_dept FOR ztabu_lib-dept_code,
  s_issue FOR ztabu_lib-issued_to,
  s_idate FOR ztabu_lib-issued_on.

"show all books Vs only issued
"This is The Customized CheckBox I have Added for Users
"For Them To display - all Books or only those Currently Issued.
PARAMETERS p_all AS CHECKBOX DEFAULT 'X'.


"Types (Structure) for output Internal Table
"I have Added a person_type field : Distinguish btw who is the Borrower.
TYPES : BEGIN OF ty_out,
        book_id      TYPE ztabu_lib-book_id,
        book_name   TYPE ztabu_lib-book_name,
        dept_code   TYPE ztabu_lib-dept_code,
        dept_text   TYPE ztabu_department-dept_text, "description
        issued_to   TYPE ztabu_lib-issued_to,
        issued_on   TYPE ztabu_lib-issued_on,
        return_date TYPE ztabu_lib-return_date,
        person_type TYPE char20,                        "STUDENT/TEACHER/NOT ISSUED
        first_name  TYPE ztabu_student-first_name,
        last_name   TYPE ztabu_student-last_name,
        phone       TYPE ztabu_student-phone,
        email_id    TYPE ztabu_student-email_id,
        city        TYPE ztabu_student-city,
        region_desc TYPE ztabu_region-region_desc,

        END OF ty_out.

"Creating Internal Table and Workarea
DATA : gt_out TYPE TABLE OF ty_out,
       gs_out TYPE ty_out.


" Raw Select Line Type
TYPES : BEGIN OF ty_raw,

         book_id      TYPE ztabu_lib-book_id,
         book_name    TYPE ztabu_lib-book_name,
         dept_code    TYPE ztabu_lib-dept_code,
         dept_text    TYPE ztabu_department-dept_text,
         issued_to    TYPE ztabu_lib-issued_to,
         issued_on    TYPE ztabu_lib-issued_on,
         return_date  TYPE ztabu_lib-return_date,

         student_id   TYPE ztabu_student-student_id,
         s_fname      TYPE ztabu_student-first_name,
         s_lname      TYPE ztabu_student-last_name,
         s_phone      TYPE ztabu_student-phone,
         s_email      TYPE ztabu_student-email_id,
         s_city        TYPE ztabu_student-city,
         s_region_desc TYPE ztabu_region-region_desc,

         teacher_id   TYPE ztabu_teacher-teacher_id,
         t_fname      TYPE ztabu_teacher-first_name,
         t_lname      TYPE ztabu_teacher-last_name,
         t_phone      TYPE ztabu_teacher-phone,
         t_email      TYPE ztabu_teacher-email_id,
         t_city       TYPE ztabu_teacher-city,
         t_region_desc TYPE ztabu_region-region_desc,
       END OF ty_raw.


DATA : lt_raw TYPE TABLE OF ty_raw.

FIELD-SYMBOLS: <r> TYPE ty_raw.


"Start Of Selection
START-OF-SELECTION.
        PERFORM get_data.
        "Displaying an Error Message if Data is not entered in the Selection Screen
        IF gt_out IS INITIAL.
          MESSAGE 'No Data Found for Given Selection' TYPE 'S' DISPLAY LIKE 'E'.
          EXIT.
        ENDIF.

        PERFORM display_alv.


"Fetch data from DB With Joins.
FORM GET_DATA .

  "Read LIBRead LIB + DEPARTMENT + possible STUDENT + possible TEACHER + REGION (student/teacher)
   SELECT
     a~book_id,
     a~book_name,
     a~dept_code,
     d~dept_text AS dept_text,
     a~issued_to,
     a~issued_on,
     a~return_date,

     s~student_id,
     s~first_name       AS s_fname,
     s~last_name        AS s_lname,
     s~phone            AS s_phone,
     s~email_id         AS s_email,
     s~city             AS s_city,
     rs~region_desc     AS s_region_desc,

     t~teacher_id,
     t~first_name        AS t_fname,
     t~last_name         AS t_lname,
     t~phone             AS t_phone,
     t~email_id          AS t_email,
     t~city              AS t_city,
     rt~region_desc      AS t_region_desc

     FROM ztabu_lib AS a
     LEFT JOIN ztabu_department AS  d  ON  d~dept_code = a~dept_code
     LEFT JOIN ztabu_student    AS  s  ON  s~student_id = a~issued_to
     LEFT JOIN ztabu_teacher    AS  t  ON  t~teacher_id = a~issued_to
     LEFT JOIN ztabu_region     AS  rs ON  rs~region_code = s~region_code
     LEFT JOIN ztabu_region     AS  rt ON  rt~region_code = t~region_code


   " Isuued to or not (OR) Issued to
   WHERE ( @p_all = 'X' OR a~issued_to <> '' ) "( @p_all = 'X' OR a~issued_to <> '' ) or IS NOT INITIAL
     " iF THE issuer is a student
     AND a~book_id      IN  @s_bookid
     AND a~book_name    IN  @s_bname
     AND a~dept_code    IN  @s_dept
     AND a~issued_to    IN  @s_issue
     AND a~issued_on    IN  @s_idate
    INTO TABLE @DATA(lt_raw).

LOOP AT lt_raw ASSIGNING FIELD-SYMBOL(<r>).

  CLEAR gs_out.

  gs_out-book_id      = <r>-book_id.
  gs_out-book_name    = <r>-book_name.
  gs_out-dept_code    = <r>-dept_code.
  gs_out-dept_text    = <r>-dept_text.
  gs_out-issued_to    = <r>-issued_to.
  gs_out-issued_on    = <r>-issued_on.
  gs_out-return_date  = <r>-return_date.

  "Check Whether Issued to is Student or Teacher

  IF <r>-student_id IS NOT INITIAL.
    gs_out-person_type    = 'STUDENT'.
    gs_out-first_name     = <r>-s_fname.
    gs_out-last_name      = <r>-s_lname.
    gs_out-phone          = <r>-s_phone.
    gs_out-email_id       = <r>-s_email.
    gs_out-city           = <r>-s_city.
    gs_out-region_desc    = <r>-s_region_desc.

  ELSEIF <r>-teacher_id IS NOT INITIAL.
    gs_out-person_type = 'TEACHER'.
    gs_out-first_name  = <r>-t_fname.
    gs_out-last_name   = <r>-t_lname.
    gs_out-phone       = <r>-t_phone.
    gs_out-email_id    = <r>-t_email.
    gs_out-city        = <r>-t_city.
    gs_out-region_desc = <r>-t_region_desc.

  ELSE.
    gs_out-person_type = 'NOT ISSUED'.

  ENDIF.
  APPEND gs_out TO gt_out.

ENDLOOP.

ENDFORM.


"Display Using Classical ALV - GRID
FORM DISPLAY_ALV .

DATA : lt_fcat    TYPE  slis_t_fieldcat_alv,
       ls_fcat    TYPE  slis_fieldcat_alv,
       ls_layout  TYPE  slis_layout_alv.

"Layout Zebra pattern
ls_layout-zebra             = 'X'.
ls_layout-colwidth_optimize = 'X'.

"Macro to add Columns Easily
DEFINE add_fcat.
  CLEAR ls_fcat.
  ls_fcat-fieldname = &1.
  ls_fcat-seltext_m = &2.
  APPEND ls_fcat TO lt_fcat.
END-OF-DEFINITION.


"Building Customized Fieldcatalog (Order of Display)
add_fcat 'BOOK_ID' 'Book ID'.
add_fcat 'BOOK_NAME'   'Book Name'.
add_fcat 'DEPT_CODE'   'Dept'.
add_fcat 'DEPT_TEXT'   'Dept Desc'.
add_fcat 'ISSUED_TO'   'Issued To'.
add_fcat 'ISSUED_ON'   'Issued On'.
add_fcat 'RETURN_DATE' 'Return Date'.
add_fcat 'PERSON_TYPE' 'Issued Type'.
add_fcat 'FIRST_NAME'  'First Name'.
add_fcat 'LAST_NAME'   'Last Name'.
add_fcat 'PHONE'       'Phone'.
add_fcat 'EMAIL_ID'    'Email'.
add_fcat 'CITY'        'City'.
add_fcat 'REGION_DESC' 'Region'.


"Calling the Function Module to display in Grid Format.
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
 EXPORTING
   IS_LAYOUT                         = ls_layout
   IT_FIELDCAT                       = lt_fcat
  TABLES
    T_OUTTAB                          = gt_out
 EXCEPTIONS
   PROGRAM_ERROR                     = 1
   OTHERS                            = 2.
IF SY-SUBRC <> 0.
* Implement suitable error handling here
  MESSAGE 'ALV could not be displayed due to an unexpected error.' TYPE 'E'.
ENDIF.


ENDFORM.
