insert into task_output_file (task_id, file_id, file, path)
select %s,
       (select if(max(file_id) is null,
                  1,
                  max(file_id)+1)
        from task_output_file
        where task_id=%s),
        %s,
        %s;
