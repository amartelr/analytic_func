

create table bricks (
brick_id integer,
colour varchar2(10),
shape varchar2(10),
weight integer
);

insert into bricks values ( 1, 'blue', 'cube', 1 );
insert into bricks values ( 2, 'blue', 'pyramid', 2 );
insert into bricks values ( 3, 'red', 'cube', 1 );
insert into bricks values ( 4, 'red', 'cube', 2 );
insert into bricks values ( 5, 'red', 'pyramid', 3 );
insert into bricks values ( 6, 'green', 'pyramid', 1 );

commit;