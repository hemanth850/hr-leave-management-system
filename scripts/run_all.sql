WHENEVER SQLERROR EXIT SQL.SQLCODE;

PROMPT Creating tables...
@ddl/001_create_tables.sql

PROMPT Seeding reference data...
@data/seed/001_seed_data.sql

PROMPT Setup completed successfully.
