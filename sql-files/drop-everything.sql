REM ****************************************************
REM drop tables in the right order
drop table entities;
drop table groups;
drop table users;
drop table companies;
drop table group_memberships;
drop table resources;
drop table posts;
drop table connections;
drop table comments;

REM ****************************************************
REM drop all the sequences
drop sequence users_seq;
drop sequence entities_seq;
drop sequence groups_seq;
drop sequence companies_seq;
drop sequence memberships_seq;
drop sequence posts_seq;
drop sequence resources_seq;
drop sequence connections_seq;
drop sequence comments_seq;

REM ****************************************************
REM drop packages & triggers
drop package state_pkg;
drop trigger users_bi;
drop trigger groups_bi;
drop trigger users_aifer;
drop trigger groups_aifer;
drop trigger users_ai;
drop trigger groups_ai;
