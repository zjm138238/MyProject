321 1 select @rid from (traverse out() from (select from v_instance_app where name='app0') maxdepth 4) 
