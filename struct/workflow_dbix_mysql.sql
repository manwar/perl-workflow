CREATE TABLE workflow (
  id                int not null auto_increment,
  type              varchar(50) not null,
  state             varchar(30) not null,
  last_update       timestamp,
  context           blob,
  primary key ( id )
);

CREATE TABLE workflow_history (
  id                int not null auto_increment,
  workflow_id       int not null,
  action            varchar(25) not null,
  description       varchar(4000) null,
  state             varchar(30) not null,
  user              varchar(50) null,
  date              timestamp,
  primary key( id )
);
