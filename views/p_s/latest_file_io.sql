/*
 * View: latest_file_io
 *
 * Latest file IO, by file / thread
 *
 * mysql> select * from latest_file_io limit 5;
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | thread               | file                                   | latency    | operation | requested |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 µs    | write     | 124 bytes |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 µs    | write     | 2 bytes   |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * 5 rows in set (0.05 sec)
 *
 * Versions: 5.5+
 */

DROP VIEW IF EXISTS latest_file_io;

CREATE SQL SECURITY INVOKER VIEW latest_file_io AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       format_path(object_name) file, 
       format_time(timer_wait) AS latency, 
       operation, 
       format_bytes(number_of_bytes) AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;

/*
 * View: latest_file_io_raw
 *
 * Latest file IO, by file / thread without formatting
 *
 * mysql> SELECT * FROM latest_file_io_raw LIMIT 5;
 * +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
 * | thread           | file                                                                               | latency     | operation | requested |
 * +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
 * | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ |    26152490 | write     |      4210 |
 * | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ | 30062722690 | sync      |      NULL |
 * | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/user_summary_by_statement_type.frm~ |    34144890 | close     |      NULL |
 * | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/check_lost_instrumentation.frm      |   113001980 | open      |      NULL |
 * | root@localhost:6 | /Users/mark/sandboxes/msb_5_7_2/data/ps_helper/check_lost_instrumentation.frm      |     9553180 | read      |        10 |
 * +------------------+------------------------------------------------------------------------------------+-------------+-----------+-----------+
 * 5 rows in set (0.10 sec)
 *
 * Versions: 5.5+
 */

DROP VIEW IF EXISTS latest_file_io_raw;

CREATE SQL SECURITY INVOKER VIEW latest_file_io_raw AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       object_name file, 
       timer_wait AS latency, 
       operation, 
       number_of_bytes AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
   AND event_name LIKE 'wait/io/file/%'
 ORDER BY timer_start;
