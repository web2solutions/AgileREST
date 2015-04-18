-- Table: gridmaker_table

-- DROP TABLE gridmaker_table;

CREATE TABLE gridmaker_table
(
  gridmaker_table_id serial NOT NULL,
  field_id integer DEFAULT 0,
  table_name character varying(400) NOT NULL,
  grid_name character varying(400) NOT NULL,
  grid_date_format character varying(100) DEFAULT '%m-%d-%Y'::character varying,
  CONSTRAINT gridmaker_table_pkey PRIMARY KEY (gridmaker_table_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE gridmaker_table
  OWNER TO eduardoalmeida;



-- Table: gridmaker_column

-- DROP TABLE gridmaker_column;

CREATE TABLE gridmaker_column
(
  gridmaker_column_id serial NOT NULL,
  gridmaker_table_id integer NOT NULL,
  column_name character varying(400) NOT NULL,
  column_type character varying(100) DEFAULT 'varchar(300)'::character varying,
  dhtmlx_grid_header character varying(400) NOT NULL,
  dhtmlx_grid_type character varying(10) DEFAULT 'txttxt'::character varying,
  dhtmlx_grid_sorting character varying(10) DEFAULT 'str'::character varying,
  dhtmlx_grid_width character varying(10) DEFAULT '*'::character varying,
  dhtmlx_grid_align character varying(10) DEFAULT 'left'::character varying,
  dhtmlx_grid_footer character varying(400) DEFAULT ''::character varying,
  CONSTRAINT gridmaker_column_pkey PRIMARY KEY (gridmaker_column_id),
  CONSTRAINT gridmaker_table_id_fkey FOREIGN KEY (gridmaker_table_id)
      REFERENCES gridmaker_table (gridmaker_table_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT
)
WITH (
  OIDS=FALSE
);
ALTER TABLE gridmaker_column
  OWNER TO eduardoalmeida;




-- Table: groups

-- DROP TABLE groups;

CREATE TABLE groups
(
  group_id serial NOT NULL,
  name character varying(255) NOT NULL,
  CONSTRAINT groups_pkey PRIMARY KEY (group_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE groups
  OWNER TO eduardoalmeida;


---------------------------- Persons
-- Table: persons

-- DROP TABLE persons;

CREATE TABLE persons
(
  person_id serial NOT NULL,
  company_id integer NOT NULL,
  company_branch_id integer NOT NULL,
  group_id integer NOT NULL,
  first_name character varying(255) NOT NULL,
  last_name character varying(255) NOT NULL,
  email character varying(255) DEFAULT ''::character varying,
  username character varying(300),
  password character varying(300),
  title character varying(255),
  CONSTRAINT persons_pkey PRIMARY KEY (person_id),
  CONSTRAINT group_id_fkey FOREIGN KEY (group_id)
      REFERENCES groups (group_id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE persons
  OWNER TO eduardoalmeida;

-- Persons' triggers

CREATE OR REPLACE FUNCTION person_update_password() RETURNS trigger AS $$
BEGIN
    IF tg_op = 'INSERT' OR tg_op = 'UPDATE' THEN
	IF NEW.password <> OLD.password THEN
		NEW.password = encode( digest(NEW.password, 'sha256') , 'hex');
	END IF;
	RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_person_update_password 
BEFORE INSERT OR UPDATE ON persons 
FOR EACH ROW EXECUTE PROCEDURE person_update_password();

-- 

CREATE OR REPLACE FUNCTION person_update_username() RETURNS trigger AS $$
BEGIN
    IF tg_op = 'INSERT' OR tg_op = 'UPDATE' THEN
	IF NEW.email <> OLD.email THEN
		NEW.username = NEW.email;
	END IF;
	RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_person_update_username 
BEFORE INSERT OR UPDATE ON persons 
FOR EACH ROW EXECUTE PROCEDURE person_update_username();

---------------------------- Persons





CREATE TABLE api_access_token
(
  api_access_token_id serial NOT NULL,
  person_id integer NOT NULL,
  token  text,
  date_creation bigint, -- I want epoch time here (seconds)
  date_expiration bigint, -- I want epoch time here (seconds) -- default today + 1 day
  active_status integer NOT NULL default 0,
  CONSTRAINT api_access_token_pkey PRIMARY KEY (api_access_token_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE api_access_token
  OWNER TO eduardoalmeida;


CREATE TABLE api_allowed_origin
(
  api_allowed_origin_id serial NOT NULL,
  user_id integer NOT NULL,
  origin  text,
  CONSTRAINT api_allowed_origin_pkey PRIMARY KEY (api_allowed_origin_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE api_allowed_origin
  OWNER TO eduardoalmeida;





 -- hosts allowed to fecth content from API
insert into tbl_api_allowed_origin(origin) values('http://mac.web2.eti.br');

----- END


