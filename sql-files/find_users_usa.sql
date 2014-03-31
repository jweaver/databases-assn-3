select first_name, last_name, user_id, email from users where entity_id IN (select from_entity from connections where to_entity IN (select entity_id from groups)) AND country = 'USA';
