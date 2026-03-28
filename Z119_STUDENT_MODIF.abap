*&---------------------------------------------------------------------*
*& Report Z119_STUDENT_MODIF
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z119_STUDENT_MODIF.

TABLES: ZTABU_STUDENT.

TYPE-POOLS: slis.

*------------- BLOCK 1 - MODE SELECTION -----------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: r_disp RADIOBUTTON GROUP g1 DEFAULT 'X',
              r_mod  RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b1.

*------------ BLOCK 2 - DISPLAY STUDENT --------------------
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS: s_stid FOR ZTABU_STUDENT-STUDENT_ID MODIF ID dis.

  PARAMETERS: p_dept TYPE ZTABU_STUDENT-DEPT_CODE MODIF ID dis, "MODIF ID - group multiple screen elements together
              p_year TYPE ZTABU_STUDENT-YEAR_STU MODIF ID dis.
SELECTION-SCREEN END OF BLOCK b2.

*------------ BLOCK 3 - MODIFY STUDENT ------------------
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS: p_fname TYPE ZTABU_STUDENT-FIRST_NAME   MODIF ID mod,
              p_lname TYPE ZTABU_STUDENT-LAST_NAME    MODIF ID mod,
              p_dob   TYPE ZTABU_STUDENT-DATE_OF_BIRTH MODIF ID mod,
              p_admdt TYPE ZTABU_STUDENT-ADM_DATE      MODIF ID mod,
              p_depcd TYPE ZTABU_STUDENT-DEPT_CODE     MODIF ID mod,
              p_year_m TYPE ZTABU_STUDENT-YEAR_STU       MODIF ID mod,
              p_phone TYPE ZTABU_STUDENT-PHONE         MODIF ID mod,
              p_email TYPE ZTABU_STUDENT-EMAIL_ID      MODIF ID mod,
              p_city  TYPE ZTABU_STUDENT-CITY          MODIF ID mod,
              p_reg   TYPE ZTABU_STUDENT-REGION_CODE   MODIF ID mod.
SELECTION-SCREEN END OF BLOCK b3.

*------------ DYNAMIC SCREEN CONTROL -------------------
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF r_disp = 'X'.    "if display selected
      IF screen-group1 = 'MOD'.  "inactive modify screen
        screen-active = 0.
      ENDIF.
    ELSE.
      IF screen-group1 = 'DIS'. "if modify selected
        screen-active = 0.     "inactive display screen
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

*----------- START OF SELECTION -------------------------
START-OF-SELECTION.
  IF r_disp = 'X'.
    PERFORM display_students.
  ELSE.
    PERFORM modify_student.
  ENDIF.

*----------- DISPLAY STUDENTS (ALV) ----------------------
FORM display_students.
  DATA: lt_student  TYPE TABLE OF ZTABU_STUDENT,
        lt_fieldcat TYPE slis_t_fieldcat_alv,
        ls_layout   TYPE slis_layout_alv.

  " Select logic based on your ranges
  SELECT * FROM ztabu_student
    INTO TABLE lt_student
    WHERE year_stu   = p_year
      AND student_id IN s_stid
      AND dept_code  = p_dept.

  IF lt_student IS INITIAL.
    MESSAGE 'No data found for the selected criteria' TYPE 'I'.
    RETURN.
  ENDIF.

  PERFORM build_fieldcat CHANGING lt_fieldcat.

  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-repid
      i_callback_top_of_page = 'TOP_OF_PAGE' " Matches the FORM name below
      is_layout              = ls_layout
      it_fieldcat            = lt_fieldcat
    TABLES
      t_outtab               = lt_student
    EXCEPTIONS
      others                 = 1.
ENDFORM.

*------------------ MODIFY STUDENT -------------------
FORM modify_student.
  DATA: lv_last_id  TYPE ZTABU_STUDENT-STUDENT_ID,
        lv_new_id   TYPE ZTABU_STUDENT-STUDENT_ID,
        ls_student  TYPE ZTABU_STUDENT.

  " Validation
  IF p_fname IS INITIAL OR p_lname IS INITIAL.
    MESSAGE 'First Name and Last Name are mandatory' TYPE 'E'.
  ENDIF.

" lock before only to prevent race condition
*User A locks 00000000.
*User B tries to lock 00000000 but the system says "Wait, someone else is generating an ID right now."
  CALL FUNCTION 'ENQUEUE_EZ119_STUDENT_LO'
    EXPORTING
      student_id     = '00000000' " Use a dummy value to sync the process
    EXCEPTIONS
      foreign_lock   = 1
      others         = 2.

  IF sy-subrc <> 0.
    MESSAGE 'System busy. Please try again in a moment.' TYPE 'E'.
    RETURN.
  ENDIF.

  " 3. ID Generation (MUST be inside the lock)
  SELECT MAX( student_id ) FROM ztabu_student INTO lv_last_id.
  lv_new_id = lv_last_id + 1.
"takes a "raw" number and pads it with zeros to fill the entire length of the field.
"The next time you run the report, SELECT MAX will correctly see 00000101 as the highest value
"  because all IDs have the same number of digits.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_new_id
    IMPORTING
      output = lv_new_id.

  " 4. Data Mapping
  ls_student-student_id    = lv_new_id.
  ls_student-first_name    = p_fname.
  ls_student-last_name     = p_lname.
  ls_student-date_of_birth = p_dob.
  ls_student-adm_date      = p_admdt.
  ls_student-dept_code     = p_depcd.
  ls_student-year_stu      = p_year_m.
  ls_student-phone         = p_phone.
  ls_student-email_id      = p_email.
  ls_student-city          = p_city.
  ls_student-region_code   = p_reg.


  " 5. Insert
  INSERT ztabu_student FROM ls_student.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Student created successfully with ID { lv_new_id }| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Error inserting record - ID might already exist' TYPE 'E'.
  ENDIF.

  " 6. DEQUEUE
  CALL FUNCTION 'DEQUEUE_EZ119_STUDENT_LO'
    EXPORTING
      student_id = '00000000'.
ENDFORM.

*----------------- TOP OF PAGE -------------------
" Make sure this name matches I_CALLBACK_TOP_OF_PAGE exactly
FORM top_of_page.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.

  CLEAR ls_header.
  ls_header-typ  = 'S'. "SELECTION TEXT
  ls_header-info = |Run Date: { sy-datum DATE = USER } | &&
                   |Run Time: { sy-uzeit TIME = USER } | &&
                   |Run By: { sy-uname }|.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.

*------------- Field Catalog --------------
FORM build_fieldcat CHANGING pt_fieldcat TYPE slis_t_fieldcat_alv.
  DATA ls TYPE slis_fieldcat_alv.

  DEFINE m_fieldcat.
    ls-fieldname = &1.
    ls-seltext_m = &2.
    append ls to pt_fieldcat.
    clear ls.
  END-OF-DEFINITION.

  m_fieldcat 'STUDENT_ID' 'Student ID'.
  m_fieldcat 'FIRST_NAME' 'First Name'.
  m_fieldcat 'LAST_NAME'  'Last Name'.
  m_fieldcat 'DEPT_CODE'  'Dept'.
  m_fieldcat 'YEAR_STU'   'Year'.
ENDFORM.
