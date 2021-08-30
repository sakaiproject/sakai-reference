
-- START SAK-44932

UPDATE gb_grading_scale_t SET NAME = 'letter_grades'      WHERE ID = 1;
UPDATE gb_grading_scale_t SET NAME = 'letter_grades_plus' WHERE ID = 2;
UPDATE gb_grading_scale_t SET NAME = 'pass_not_pass'      WHERE ID = 3;
UPDATE gb_grading_scale_t SET NAME = 'points'             WHERE ID = 4;

-- END SAK-44932

