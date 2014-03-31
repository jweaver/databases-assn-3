REM ************************************************************
REM the entities table is a way of unifying generic entities that can make posts
CREATE TABLE entities (
       entity_id NUMBER NOT NULL,
       entity_type VARCHAR2(30) NOT NULL,
       CONSTRAINT cons_entities_entity_type CHECK(entity_type IN('user', 'group', 'company')),
       CONSTRAINT entity_pk PRIMARY KEY (entity_id)
);

REM Lets us easily enter in new entities to a unique id
CREATE SEQUENCE entities_seq
       MINVALUE 1
       START WITH 1
       INCREMENT BY 1
       CACHE 20;

REM ************************************************************
REM create the companies table
CREATE TABLE companies (
       company_id NUMBER NOT NULL,
       entity_id NUMBER,
       name VARCHAR2(40) NOT NULL,
       CONSTRAINT company_pk PRIMARY KEY (company_id)
);

ALTER TABLE companies
       ADD ( CONSTRAINT companies_entity_id_fk FOREIGN KEY (entity_id) REFERENCES entities(entity_id) ON DELETE CASCADE );

REM use a sequence for easy entry of the membership ids.
CREATE SEQUENCE companies_seq
       MINVALUE 1
       START WITH 4001
       INCREMENT BY 1
       NOCACHE;


REM ************************************************************
REM Users table stores each user of the mock linkedin db.
CREATE TABLE users (
       user_id NUMBER NOT NULL,
       entity_id NUMBER,
       email VARCHAR2(254) NOT NULL,
       first_name VARCHAR2(20),
       last_name VARCHAR2(25),
       country VARCHAR2(40),
       zip NUMBER(6),
       registration_date DATE DEFAULT sysdate,
       current_status VARCHAR2(10) NOT NULL,
       CONSTRAINT cons_users_current_status CHECK(current_status IN('Employed', 'Student', 'Job Seeker')),
       CONSTRAINT user_pk PRIMARY KEY (user_id)
);

ALTER TABLE users
      ADD ( CONSTRAINT users_entity_id_fk FOREIGN KEY (entity_id) REFERENCES entities(entity_id) ON DELETE CASCADE );

REM Use a sequence for easy entry of the user IDs, via users_seq.nextval
CREATE SEQUENCE users_seq
       MINVALUE 1
       START WITH 1
       INCREMENT BY 1
       CACHE 20;

REM ************************************************************
REM create the group (memberships) table
CREATE TABLE groups (
       group_id NUMBER NOT NULL,
       name VARCHAR2(100),
       entity_id NUMBER,
       CONSTRAINT group_pk PRIMARY KEY (group_id)
);

ALTER TABLE groups
      ADD ( CONSTRAINT groups_entity_id_fk FOREIGN KEY (entity_id) REFERENCES entities(entity_id) ON DELETE CASCADE );

REM use a sequence for easy entry of the group ids.  Looks like the fake data starts at 56701 for some reason.
CREATE SEQUENCE groups_seq
       MINVALUE 1
       START WITH 56701
       INCREMENT BY 1
       NOCACHE;


REM ************************************************************
REM create the group_memberships table (mapping rel table)
CREATE TABLE group_memberships (
       user_id NUMBER NOT NULL,
       group_id NUMBER NOT NULL,
       join_date DATE DEFAULT sysdate,
       membership_id NUMBER NOT NULL,
       CONSTRAINT group_memberships_pk PRIMARY KEY (membership_id)
);

REM use a sequence for easy entry of the membership ids.
        CREATE SEQUENCE memberships_seq
        MINVALUE 1
        START WITH 1
        INCREMENT BY 1
        NOCACHE;

ALTER TABLE group_memberships
      ADD (
          CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
          CONSTRAINT group_id_fk FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
);


REM ************************************************************
REM ************************************************************
REM a 3-trigger setup with package state is needed in order to consistently keep entities "in synch" with groups, users, companies
CREATE OR REPLACE PACKAGE state_pkg
       AS
                TYPE ridArray IS TABLE OF rowid index by binary_integer;
                newRows ridArray;
                TYPE entityUserArray IS TABLE OF number index by binary_integer;
                newEntitiesRows entityUserArray;

                emptyRows ridArray;
                emptyEntities entityUserArray;
       END;
       /

REM resets the statepackage regarding users tbl
CREATE OR REPLACE TRIGGER users_bi
       BEFORE INSERT OR UPDATE ON users
       BEGIN
                state_pkg.newRows := state_pkg.emptyRows;
                state_pkg.newEntitiesRows := state_pkg.emptyEntities;
       END;
       /

REM resets the statepackage regarding groups tbl
CREATE OR REPLACE TRIGGER groups_bi
       BEFORE INSERT OR UPDATE ON groups
       BEGIN
                state_pkg.newRows := state_pkg.emptyRows;
                state_pkg.newEntitiesRows := state_pkg.emptyEntities;
       END;
       /

REM resets the statepackage regarding companies tbl
CREATE OR REPLACE TRIGGER companies_bi
       BEFORE INSERT OR UPDATE ON companies
       BEGIN
               state_pkg.newRows := state_pkg.emptyRows;
               state_pkg.newEntitiesRows := state_pkg.emptyEntities;
       END;
       /

REM saves the rowID into the statepackage array
REM also create the new entity & store its ID
CREATE OR REPLACE TRIGGER users_aifer
       AFTER INSERT OR UPDATE OF user_id on users FOR EACH ROW
       DECLARE
                new_user_entity_fk number;
       BEGIN
                new_user_entity_fk := entities_seq.nextval;
                state_pkg.newRows( state_pkg.newRows.count+1 ) := :new.rowid;
                INSERT INTO entities (entity_id, entity_type) VALUES (new_user_entity_fk, 'user');
                state_pkg.newEntitiesRows( state_pkg.newEntitiesRows.count+1 ) := new_user_entity_fk;
       END;
       /

REM saves the rowID into the statepackage array
REM also create the new entity & store its ID
CREATE OR REPLACE TRIGGER groups_aifer
       AFTER INSERT OR UPDATE OF group_id on groups FOR EACH ROW
       DECLARE
               new_group_entity_fk number;
       BEGIN
                new_group_entity_fk := entities_seq.nextval;
                state_pkg.newRows( state_pkg.newRows.count+1 ) := :new.rowid;
                INSERT INTO entities (entity_id, entity_type) VALUES (new_group_entity_fk, 'group');
                state_pkg.newEntitiesRows( state_pkg.newEntitiesRows.count+1 ) := new_group_entity_fk;
       END;
       /

REM saves the rowID into the statepackage array
REM also create the new entity & store its ID
CREATE OR REPLACE TRIGGER companies_aifer
       AFTER INSERT OR UPDATE OF company_id on companies FOR EACH ROW
       DECLARE
               new_company_entity_fk number;
       BEGIN
                new_company_entity_fk := entities_seq.nextval;
                state_pkg.newRows( state_pkg.newRows.count+1 ) := :new.rowid;
                INSERT INTO entities (entity_id, entity_type) VALUES (new_company_entity_fk, 'company');
                state_pkg.newEntitiesRows( state_pkg.newEntitiesRows.count+1 ) := new_company_entity_fk;
       END;
       /

REM processes the entries in the array of the statepackage, in order
CREATE OR REPLACE TRIGGER users_ai
       AFTER INSERT OR UPDATE OF user_id ON users
       BEGIN
                FOR i IN 1 .. state_pkg.newRows.count LOOP
                    UPDATE users SET entity_id = state_pkg.newEntitiesRows(i) WHERE rowid = state_pkg.newRows(i);
                END LOOP;
       END;
       /

REM processes the entries in the array of the statepackage, in order
CREATE OR REPLACE TRIGGER groups_ai
       AFTER INSERT OR UPDATE OF group_id ON groups
       BEGIN
               FOR i IN 1 .. state_pkg.newRows.count LOOP
                      UPDATE groups SET entity_id = state_pkg.newEntitiesRows(i) WHERE rowid = state_pkg.newRows(i);
               END LOOP;
       END;
       /

REM processes the entries in the array of the statepackage, in order
CREATE OR REPLACE TRIGGER companies_ai
       AFTER INSERT OR UPDATE OF company_id ON companies
       BEGIN
               FOR i IN 1 .. state_pkg.newRows.count LOOP
                   UPDATE companies SET entity_id = state_pkg.newEntitiesRows(i) WHERE rowid = state_pkg.newRows(i);
               END LOOP;
       END;
       /


REM ************************************************************
REM create the resources (files, attachments, etc) table
CREATE TABLE resources (
       resource_id NUMBER NOT NULL,
       resource_type VARCHAR2(20) NOT NULL,
       link VARCHAR2(80) NOT NULL,
       owner_id NUMBER NOT NULL,
       post_id NUMBER,
       CONSTRAINT resource_pk PRIMARY KEY (resource_id)
);

REM ************************************************************
REM create the posts table
CREATE TABLE posts (
       post_id NUMBER NOT NULL,
       content VARCHAR2(500) NOT NULL,
       author_id NUMBER NOT NULL,
       recipient_id NUMBER NOT NULL,
       post_type VARCHAR2(20) NOT NULL,
       created_on DATE DEFAULT sysdate,
       share_type VARCHAR2(20) NOT NULL,
       resource_attachment_id NUMBER,
       CONSTRAINT posts_id_pk PRIMARY KEY (post_id),
       CONSTRAINT cons_posts_post_type CHECK(post_type IN('connection', 'group', 'company')),
       CONSTRAINT cons_posts_share_type CHECK(share_type IN('public', 'connection'))
);

ALTER TABLE posts
      ADD ( CONSTRAINT posts_author_id_fk FOREIGN KEY (author_id) REFERENCES entities(entity_id) ON DELETE CASCADE,
            CONSTRAINT posts_recipient_id_fk FOREIGN KEY (recipient_id) REFERENCES entities(entity_id) ON DELETE CASCADE,
            CONSTRAINT posts_resource_id_fk FOREIGN KEY (resource_attachment_id) REFERENCES resources(resource_id) ON DELETE SET NULL);

REM Use a sequence which assists entering posts in for post_id
CREATE SEQUENCE posts_seq
    MINVALUE 101
    START WITH 101
    INCREMENT BY 1
    CACHE 20;


REM ************************************************************
ALTER TABLE resources
      ADD (
          CONSTRAINT owner_id_fk FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
          CONSTRAINT post_id_fk FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

REM use a sequence for easy entry of the resources ids.
CREATE SEQUENCE resources_seq
    MINVALUE 1
    START WITH 8001
    INCREMENT BY 1
    NOCACHE;


REM ************************************************************
REM create the connections table (networks entities together.  directional)
CREATE TABLE connections (
       connection_id NUMBER NOT NULL,
       from_entity NUMBER,
       to_entity NUMBER,
       CONSTRAINT connection_pk PRIMARY KEY (connection_id)
);

ALTER TABLE connections
      ADD (
           CONSTRAINT connections_from_entity_fk FOREIGN KEY (from_entity) REFERENCES entities(entity_id) ON DELETE CASCADE,
           CONSTRAINT connections_to_entity_fk FOREIGN KEY (to_entity) REFERENCES entities(entity_id) ON DELETE CASCADE
);

REM use a sequence for easy entry of the connections ids.
CREATE SEQUENCE connections_seq
    MINVALUE 1
    START WITH 1
    INCREMENT BY 1
    NOCACHE;


REM ************************************************************
REM create the comments table, etc
CREATE TABLE comments (
       comment_id NUMBER NOT NULL,
       author_id NUMBER,
       post_id NUMBER,
       content VARCHAR2(256) NOT NULL,
       is_liked NUMBER,
       is_shared NUMBER,
       written_on DATE DEFAULT sysdate,
       CONSTRAINT comments_comment_id_pk PRIMARY KEY (comment_id)
);

ALTER TABLE comments
      ADD (
          CONSTRAINT comments_author_id_fk FOREIGN KEY (author_id) REFERENCES entities(entity_id) ON DELETE CASCADE,
          CONSTRAINT comments_post_id_fk FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

REM use a sequence for easy entry of the comments ids.
CREATE SEQUENCE comments_seq
       MINVALUE 701
       START WITH 701
       INCREMENT BY 1
       NOCACHE;
